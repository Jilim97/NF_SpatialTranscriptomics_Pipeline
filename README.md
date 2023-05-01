# NF_SpatialTranscripomics
Automated spatial transcriptomics analysis pipeline run on HPC
![NF Spatial Transcroptomics](https://github.ugent.be/jilim/NF_SpatialTranscripomics/blob/main/NF_Pipeline.jpg)

## Build Conda virtual envieonment
Donwload anaconda in your working directory
```
wget https://repo.anaconda.com/archive/Anaconda3-2023.03-1-Linux-x86_64.sh
bash Anaconda3-2023.03-1-Linux-x86_64.sh
```
you can choose your download directory during downloading

Build conda virtual environment for Spatial transcriptomics pipeline with yml file\
yml file contains all necessary R packages and nextflow
```
conda env create --name envname --file=DPST.yml
```

Activate
```
conda activate envname
```

Deactivate
```
conda deactivate
```

## Modules
Pipeline can be run in hpc that contains sra toolkit modules
Check whether versions of modules in NF_Pipeline.nf is available
```
ml spider parallel-fastq-dump
ml spider fastqc
ml spider multiqc
```

## Dowload necessary R packages
STUtility which is necessary for saptial transcriptomic can be dowlnoaded following step.

Activate and open R in conda environment
```
conda activate envname
R
```
Dowload STUtility
```
devtools::install_github(
    "jbergenstrahle/STUtility"
)
```
Check whehter it works
```
library(STUtility)
```
Extra R packages should be downloaded for further analysis over rscript from this page

## Create a Congif file
Defaulf settings of parameters can be checked in nextflow.config file
```
NXF_VER=20.04.0 nextflow run ST_Pipeline.nf --help
```

## Download SpaceRanger
SpaceRanger should be downloded in your working directory before runnning Spatial transcriptomics pipeline\
This can be checked in 10X Genomics homepage\
[10X Genomics Spaceranger](https://support.10xgenomics.com/spatial-gene-expression/software/downloads/latest)

Download SpaceRanger
```
wget -O spaceranger-2.0.1.tar.gz "https://cf.10xgenomics.com/releases/spatial-exp/spaceranger-2.0.1.tar.gz?Expires=1682555118&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9jZi4xMHhnZW5vbWljcy5jb20vcmVsZWFzZXMvc3BhdGlhbC1leHAvc3BhY2VyYW5nZXItMi4wLjEudGFyLmd6IiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoxNjgyNTU1MTE4fX19XX0_&Signature=jIx5dakc8209EdFHUVVpL~9wQ9Ls7Mn-6PLEsfbi7Hio4kpGfFCT~Wn~wP8tgQ0h8I1jkPQpi-3V98su311RoxSLttXfo4Wat08HtornlXXL6zZJho8Kwg75hdnX46zynWHjW82CXC-HKuKPfcJ~l3x6jlnmQkXI51EfadJ7ep6iPixtt94hyvfkbgluXt-XavjyUU342vqB-qirfF9HVn5yoe3t5on5mtWUNqpXRNlJHKkToce-IwPrpJytFjNtHj4HRHruL1ZbXoGDdNcsMGPL90cAQNX5tFQmnbVBjdX25q6N~ZCOsVL3h1pxqJ3FYDlq-ohxu-Vj3CAftWFi0w__&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA"
```

Install SpaceRanger in working directory
```
tar -xzvf spaceranger-2.0.1.tar.gz
```
**File name of spaceranger should kept same as spaceranger-2.0.1 (Check spoaceranger process in pipeline)**

## Download Reference Genome
Reference Genome can be downloaded in 10X Visium hompage

Mouse Reference Genome (Example fastq file can be run with this reference file)\
[10X Genomics Mouse Reference Genome](https://support.10xgenomics.com/spatial-gene-expression/software/downloads/latest)
```
wget https://cf.10xgenomics.com/supp/spatial-exp/refdata-gex-mm10-2020-A.tar.gz
tar -xzvf refdata-gex-mm10-2020-A.tar.gz
```

**Human reference genome can be found in 10X Visium hompage**

## Example files 
### Making Transcriptome file
Transcriptome file (csv) can be downloaded in 10X Visium Hompage

[10X Genomics Mouse Transcriptome](https://cf.10xgenomics.com/supp/spatial-exp/probeset/Visium_Mouse_Transcriptome_Probe_Set_v1.0_mm10-2020-A.csv)\
[10X Genomics Human Transcriptome](https://cf.10xgenomics.com/supp/spatial-exp/probeset/Visium_Human_Transcriptome_Probe_Set_v1.0_GRCh38-2020-A.csv)

### Slide image file
Slide image name with SRR00000000.png should be prepared in working directory (ex. SRR17184260_image.png)

## Downstream Analysis
Rmd file can be downloaded 

## Example Data:
#### Murine Colon (FF)
SRA id: SRR17184260, SRR17184261\
[GEO of Murine Colon dataset](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE190595)

#### Human Ovarian Cancer (FFPE)
SRA id: SRR23770995, SRR23770997\
[GEO of Human Ovarian Cancer dataset](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE227019)
