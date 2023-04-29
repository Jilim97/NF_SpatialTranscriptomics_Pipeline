# NF_SpatialTranscripomics
Automated spatial transcriptomics analysis pipeline

## Build Conda virtual envieonment
Donwload anaconda in your working directory
```
wget https://repo.anaconda.com/archive/Anaconda3-2023.03-1-Linux-x86_64.sh
bash Anaconda3-2023.03-1-Linux-x86_64.sh
```
you can choose your download directory during downloading

Build conda virtual environment for Spatial transcriptomics pipeline with yml file/
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
Now you have all necessary R packages\
Extra R packages should be downloaded for further analysis over rscript from this page

## Create a Congif file
Defaulf settings of parameters can be checked in nextflow.config file
```
NXF_VER=20.04.0 nextflow run ST_Pipeline.nf --help
```

## Download SpaceRanger
SpaceRanger should be downloded in your working directory before runnning Spatial transcriptomics pipeline\
This can be checked in 10X Visium homepage\
https://support.10xgenomics.com/spatial-gene-expression/software/downloads/latest

Download SpaceRanger
```
wget -O spaceranger-2.0.1.tar.gz "https://cf.10xgenomics.com/releases/spatial-exp/spaceranger-2.0.1.tar.gz?Expires=1682555118&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9jZi4xMHhnZW5vbWljcy5jb20vcmVsZWFzZXMvc3BhdGlhbC1leHAvc3BhY2VyYW5nZXItMi4wLjEudGFyLmd6IiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoxNjgyNTU1MTE4fX19XX0_&Signature=jIx5dakc8209EdFHUVVpL~9wQ9Ls7Mn-6PLEsfbi7Hio4kpGfFCT~Wn~wP8tgQ0h8I1jkPQpi-3V98su311RoxSLttXfo4Wat08HtornlXXL6zZJho8Kwg75hdnX46zynWHjW82CXC-HKuKPfcJ~l3x6jlnmQkXI51EfadJ7ep6iPixtt94hyvfkbgluXt-XavjyUU342vqB-qirfF9HVn5yoe3t5on5mtWUNqpXRNlJHKkToce-IwPrpJytFjNtHj4HRHruL1ZbXoGDdNcsMGPL90cAQNX5tFQmnbVBjdX25q6N~ZCOsVL3h1pxqJ3FYDlq-ohxu-Vj3CAftWFi0w__&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA"
```

Install SpaceRanger in working directory
```
tar -xzvf spaceranger-2.0.1.tar.gz
```
*File name of spaceranger should kept same as spaceranger-2.0.1 (Check Spaceranger process in nextflow)

## Download Reference Genome
Reference Genome can be downloaded in 10X Visium hompage

Mouse Reference Genome (Example fastq file can be run with this reference file\
https://support.10xgenomics.com/spatial-gene-expression/software/downloads/latest
```
wget https://cf.10xgenomics.com/supp/spatial-exp/refdata-gex-mm10-2020-A.tar.gz
tar -xzvf refdata-gex-mm10-2020-A.tar.gz
```

*Human reference genome can be found in 10X Visium hompage

## Making Transcriptome file
Transcriptome file (csv) can be downloaded in 10X Visium Hompage

Download this file\
https://cf.10xgenomics.com/supp/spatial-exp/probeset/Visium_Mouse_Transcriptome_Probe_Set_v1.0_mm10-2020-A.csv

*Human transcriptome file also can found in 10X Visium homepage

## Slide image file
Slide image name with SRR00000000.png should be prepared in working directory

## Downstream Analysis
Rmd file can be downloaded 

## Murine Colon (FF)
SRA_id: SRR17184260, SRR17184261


## Human Ovarian Cancer (FFPE)
