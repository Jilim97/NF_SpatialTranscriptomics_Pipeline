#!/usr/bin/env nextflow
/*
 * Spatial Transcriptomic pipeline
 * Authors:
 * - Jihwan Lim <jihwan.lim@ugent.be>
 * - Jinny Chun <jinny.chun@ugent.be>
 * - Ali Muhammad <muhali.ali@ugent.be>
 */


/*
 * Defines some parameters for analysis in a nextflow.config file
 * SpaceRanger should be pre-downloaded in working directory
 * Reference Genome should be pre-downloaded in working directory
 * Probeset should be pre-downloaded in working directory
 * Check 10XGenomics homepage for SpaceRanger, Reference Genome, and Probeset: https://support.10xgenomics.com/spatial-gene-expression/software/downloads/latest
 * Image file of Spaceranger should be pre-downloaded in working directory with SRA_ID name (ex:SRRxxxxxxxx_image.png) other extensions are allowed
 * Path of module environment should be changed depending on users' environment directory
 */

def helpMessage() {
    //log.info nfcoreHeader()
    log.info"""
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run ST_Pipeline.nf nextflow.conifg

    Common arguments:
      --title                       Tissue name
      --basedir                     Path of working directory
      --Existing                    Whether file existing (True or False)
    
    Find arguments:
      --fastq_directory             Path of raw fastq files already downloaded

    FasterqDump arguments:
      --sra_id                      Path of txt file containing SRA IDs
      --threads_down                Number of cores to be used for downloading files

    Rename_SR arguments:
      --zip                         Whether file compressed (True or False)
      --threads_zip                 Number of cores to be used for compressing files

    Spaceranger arguments:
      --slide_type                  Slide type (FF or FFPE)
      --description                 Description of Tissue and Count matrix
      --ref_genome                  Path of reference genome (Pre-downloaded)
      --extension                   Select the extension of an image file (ex. png, jpg, jpeg)
      --probe                       Path of probe set file with csv (Only for FFPE)
      --slide                       Type of slide (No slide detail but FF is only available for visium-1/visium-1 or visium-2 or visium-2-large)
      --imgrot                      Image roatation (Ture or Flase)
      --cores                       Number of cores to be used
      --mem                         Memory be used

    KnitR arguments:
      --R                           Path of Rmd file

    """.stripIndent()
}

if (params.help){
    helpMessage()
    exit 0
}

log.info """\
  SPATIAL TRANSCRIPTOMICS P I P E L I N E
 ==============================================
 Design_Project_G2
 ==============================================
 Cell type: ${params.title}
 working directory : ${params.basedir}
 Output directory : ${params.basedir}/results
 File existing: ${params.Existing}
 Compressed: ${params.zip}
 """

// Find raw fastq file with a name containing sra_id or specific_id or tag
process Find {
    label 'low_mem'
    time '1h'

    tag "Finding raw ${sra_id}_fastq files"

    input:
    tuple val(sra_id)

    output:
    tuple val(sra_id), path("${sra_id}_fastq") 

    script:
    """
    mkdir "${sra_id}_fastq"
    cp -r ${params.fastq_directory}/${sra_id}_* ./${sra_id}_fastq
    """
}

// Download raw fastq files from NCBI SRA selector 
process FasterqDump {
    label 'mid_mem'
    time '2h'

    conda '/kyukon/data/gent/vo/000/gvo00095/vsc45456/anaconda3/envs/modules'

    tag "Download ${sra_id}"
    
    //publishDir "${params.basedir}/results/fastq", mode: 'copy', overwrite: true

    input:
    val sra_id 

    output:
    tuple val(sra_id), path("${sra_id}_fastq") 

    script:
    """
    mkdir "${sra_id}_fastq"
    prefetch -X 100000000 ${sra_id} 
    fasterq-dump -e ${params.threads_down} -t \$PWD --include-technical --split-files -O ${sra_id}_fastq ${sra_id}
    """
}

// If file is not compressed, compress then rename it into the format that is required for spaceranger running
process Rename_SR {
    label 'mid_mem'
    time '4h'

    tag "Renaming for SpaceRanger input"

    publishDir "${params.basedir}/results/fastq_rename", mode: 'copy', overwrite: true

    input:
    tuple val(sra_id), path(fastq) 

    output:
    tuple val(sra_id), path("${sra_id}_rename") 

    script:
    if (params.zip == "False" )
    """
    mkdir "${sra_id}_rename"
    pigz -p${params.threads_zip} ${fastq}/${sra_id}_1.fastq
    pigz -p${params.threads_zip} ${fastq}/${sra_id}_2.fastq

    mv "${fastq}/${sra_id}_1.fastq.gz" "${sra_id}_rename/${sra_id}_S1_L001_R1_001.fastq.gz"
    mv "${fastq}/${sra_id}_2.fastq.gz" "${sra_id}_rename/${sra_id}_S1_L001_R2_001.fastq.gz"
    """
    else if (params.zip == "True")
    """
    mkdir "${sra_id}_rename"
    mv "${fastq}/${sra_id}_1.fastq.gz" "${sra_id}_rename/${sra_id}_S1_L001_R1_001.fastq.gz"
    mv "${fastq}/${sra_id}_2.fastq.gz" "${sra_id}_rename/${sra_id}_S1_L001_R2_001.fastq.gz"
    """
    else
        error "True or False only available: ${params.zip}"
}


// Quality Control
process FastQC {
    label 'mid_mem'
    time '2h'

    conda '/kyukon/data/gent/vo/000/gvo00095/vsc45456/anaconda3/envs/modules'    

    tag "QC on ${sra_id}"

    publishDir "${params.basedir}/results/fastqc", mode: 'copy', overwrite: true

    input:
    tuple val(sra_id), path(fastq) 

    output:
    path("${sra_id}_fastqc")

    script:
    """
    mkdir "${sra_id}_fastqc"
    fastqc --outdir ${sra_id}_fastqc -noextract ${fastq}/*
    """
}



process MultiQC {
    label 'mid_mem'
    time '2h'

    conda '/kyukon/data/gent/vo/000/gvo00095/vsc45456/anaconda3/envs/modules' 

    tag "Generating multiQC report"

    publishDir "${params.basedir}/results/multiQC", mode: 'copy', overwrite: true

    input:
    path(fastq) 

    output:
    file("*.html") 

    script:
    """
    multiqc .
    """
}

// Run Spaceranger
process SpaceRanger {
    label 'big_mem'
    time '8h'

    tag "Mkaing count matrix of ${sra_id}"

    //publishDir "${params.basedir}", mode: 'copy', overwrite: true

    input:
    tuple val(sra_id), path(fastq_file)

    output:
    tuple val(sra_id), path("${sra_id}_count") 

    script:
    if (params.slide_type == "FF" )
    """
    export PATH=${params.basedir}/spaceranger-2.0.1:$PATH
    
    spaceranger count --id="${sra_id}_count" \
        --description="${params.description}" \
        --transcriptome=${params.ref_genome} \
        --fastqs=${fastq_file} \
        --image=${params.basedir}/${sra_id}_image.${params.extension} \
        --unknown-slide=${params.slide} \
        --reorient-images=${params.imgrot} \
        --localcores=${params.cores} \
        --localmem=${params.mem}
    """
    else if (params.slide_type == "FFPE")
    """
    export PATH=${params.basedir}/spaceranger-2.0.1:$PATH
    
    spaceranger count --id="${sra_id}_count" \
        --description="${params.description}" \
        --transcriptome=${params.ref_genome} \
        --probe-set=${params.probe} \
        --fastqs=${fastq_file} \
        --image=${params.basedir}/${sra_id}_image.${params.extension} \
        --unknown-slide=${params.slide} \
        --reorient-images=${params.imgrot} \
        --localcores=${params.cores} \
        --localmem=${params.mem}
    """
    else
        error "Invalid slide type: ${params.slide_type}"
}

// Rename for R analysis
process Rename_R {
    label 'low_mem'
    time '1h'

    tag "Renaming count matric for R analysis"

    publishDir "${params.basedir}/results", mode: 'copy', overwrite: true

    input:
    tuple val(sra_id), path(count_matrix) 

    output:
    path "${sra_id}_matrix" 

    script:
    """
    mv "${count_matrix}/outs" "./${sra_id}_matrix"
    """

}


process KnitR {
    label 'low_mem'
    time '1h'

    tag "Rendering...."

    publishDir "${params.basedir}/results", mode: 'copy', overwrite: true

    input:
    path(R) 
    path(script) 

    output:
    tuple file("*.html"), file("*.rds")

    script:
    """
    Rscript -e "rmarkdown::render('${script}', output_file='STAnalysis_for_${params.title}.html', params = list(data = '${params.title}'), 'html_document')"
    """
}

workflow{
    sampleIDs = Channel
        .fromPath(params.sra_id)
        .splitText()
        .map{it -> it.trim()}

    if (params.Existing == "False" ){

        fastq_files = FasterqDump(sampleIDs) 
        rename_fastq = Rename_SR(fastq_files)

        qc_results = FastQC(rename_fastq)
        MultiQC( qc_results.collect() )

        space_ch = SpaceRanger(rename_fastq)
        Rename_ch = Rename_R(space_ch)

        Rch = Channel.fromPath( params.R )

        KnitR( Rename_ch.collect(), Rch )
    }
    else if (params.Existing == "True"){

        fastq_files = Find(sampleIDs) 
        rename_fastq = Rename_SR(fastq_files)

        qc_results = FastQC(rename_fastq)
        MultiQC( qc_results.collect() )

        space_ch = SpaceRanger(rename_fastq)
        Rename_ch = Rename_R(space_ch)

        Rch = Channel.fromPath( params.R )

        KnitR( Rename_ch.collect(), Rch )
    }
    else{
        error "Invalid parameters: ${params.fastq}"
    }
}
