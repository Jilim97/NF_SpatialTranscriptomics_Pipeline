#!/usr/bin/env nextflow
/*
 * Spatial Transcriptomic pipeline
 * Authors:
 * - Jihwan Lim <Jihwan.Lim@ugent.be>
 * - Jinny Chun <>
 * - Ali Muhammad <>
 */


/*
 * Defines some parameters for analysis in a nextflow.config file
 * SpaceRanger should be pre-downloaded in working directory
 * Refernce Genome should be pre-downloaded in working directory
 * Check 10XGenomics homepage for SpaceRanger and Reference Genome: https://support.10xgenomics.com/spatial-gene-expression/software/downloads/latest
 * Image file of Spaceranger should be pre-downloaded in working directory with SRA_ID name (ex:SRRxxxxxxxx_image.png)
 */

def helpMessage() {
    //log.info nfcoreHeader()
    log.info"""
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run space.nf nextflow.conifg

    Common arguments:
      --title                       Tissue name
      --basedir                     Path to working directory
      
    FastqDump arguments:
      --sra_id                      List of SRA ID
      --threads                     Number of core be use
      
    Spaceranger arguments:
      --slide_type                  Slide type (FF or FFPE)
      --description                 Description of Tissue and Count matrix
      --ref_genome                  Path of reference genome (Pre-downloaded)
      --probe                       Probe set reference file with csv (Only for FFPE)
      --slide                       Type of slide (No slide detail but FF is only available for visium-1)
      --imgrot                      Image roatation (Ture or Flase)
      --cores                       Number of core be used
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
  SPATIL TRANSCRIPTOMICS P I P E L I N E
 ==============================================
 Design_Project_G4
 ==============================================
 Cell type: ${params.title}
 working directory : ${params.basedir}
 Output directory : ${params.basedir}/results
 """


process FastqDump {
    label 'mid_mem'
    time '2h'

    tag "Downlod ${sra_id}"
    
    module 'parallel-fastq-dump/0.6.6-GCCcore-9.3.0-SRA-Toolkit-3.0.0-Python-3.8.2'
    
    //publishDir "${params.basedir}/results/fastq", mode: 'copy', overwrite: true

    input:
    val sra_id from params.sra_id

    output:
    tuple val(sra_id), path("${sra_id}_fastq") into fastq_files

    script:
    """
    mkdir "${sra_id}_fastq"
    parallel-fastq-dump --sra-id ${sra_id} --split-files --gzip --threads ${params.threads} --outdir ${sra_id}_fastq/
    """
}


process Rename_SR {
    label 'low_mem'
    time '1h'

    tag "Renaming for SpaceRanger input"

    publishDir "${params.basedir}/results/fastq_rename", mode: 'copy', overwrite: true

    input:
    tuple val(sra_id), path(fastq) from fastq_files

    output:
    tuple val(sra_id), path("${sra_id}_rename") into rename_fastq

    """
    mkdir "${sra_id}_rename"
    mv "${fastq}/${sra_id}_1.fastq.gz" "${sra_id}_rename/${sra_id}_S1_L001_R1_001.fastq.gz"
    mv "${fastq}/${sra_id}_2.fastq.gz" "${sra_id}_rename/${sra_id}_S1_L001_R2_001.fastq.gz"
    """
}

rename_fastq.into{fastqc_ch; spaceR_ch} //Duplicate channel for multi usage

process FastQC {
    label 'mid_mem'
    time '2h'

    tag "QC on ${sra_id}"
    
    module "FastQC/0.11.9-Java-11"

    publishDir "${params.basedir}/results/fastqc", mode: 'copy', overwrite: true

    input:
    tuple val(sra_id), path(fastq) from fastqc_ch

    output:
    path("${sra_id}_fastqc") into qc_results

    """
    mkdir "${sra_id}_fastqc"
    fastqc ${fastq}/* -o ${sra_id}_fastqc
    """
}

qc_ch = qc_results.collect()

process MultiQC {
    label 'mid_mem'
    time '2h'
    
    tag "Generating multiQC report"

    module "MultiQC/1.9-intel-2020a-Python-3.8.2"

    publishDir "${params.basedir}/results/multiQC", mode: 'copy', overwrite: true

    input:
    path(fastq) from qc_ch

    output:
    file("*.html") 

    script:
    """
    multiqc .
    """
}

process SpaceRanger {
    label 'big_mem'
    time '8h'

    tag "Mkaing count matrix of ${sra_id}"

    //publishDir "${params.basedir}", mode: 'copy', overwrite: true

    input:
    tuple val(sra_id), path(fastq_file) from spaceR_ch

    output:
    tuple val(sra_id), path("${sra_id}_count") into space_ch

    script:
    if (params.slide_type == "FF" )
    """
    export PATH=${params.basedir}/spaceranger-2.0.1:$PATH
    
    spaceranger count --id="${sra_id}_count" \
        --description="${params.description}" \
        --transcriptome=${params.ref_genome} \
        --fastqs=${fastq_file} \
        --image=${params.basedir}/${sra_id}_image.png \
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
        --image=${params.basedir}/${sra_id}_image.png \
        --unknown-slide=${params.slide} \
        --reorient-images=${params.imgrot} \
        --localcores=${params.cores} \
        --localmem=${params.mem}
    """
    else
        error "Invalid slide type: ${params.slide_type}"
}

process Rename_R {
    label 'low_mem'
    time '1h'

    tag "Renaming count matric for R analysis"

    publishDir "${params.basedir}/results", mode: 'copy', overwrite: true

    input:
    tuple val(sra_id), path(count_matrix) from space_ch

    output:
    path "${sra_id}_matrix" into Rename_ch

    script:
    """
    mv "${count_matrix}/outs" "./${sra_id}_matrix"
    """

}

R_ch = Rename_ch.collect() //Collect all output files from SpaceRanger for running R at once

process KnitR {
    label 'low_mem'
    time '1h'

    tag "Rendering...."

    publishDir "${params.basedir}/results", mode: 'copy', overwrite: true

    input:
    path(R) from R_ch
    path(script) from params.R

    output:
    file("*.html")

    script:
    """
    Rscript -e "rmarkdown::render('${script}', output_file='STAnalysis_for_${params.title}.html', params = list(data = '${params.title}'), 'html_document')"
    """
}