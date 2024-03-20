process TINC {

    publishDir params.publish_dir, mode: 'copy'

    input:
   
    tuple val(datasetID), val(patientID), val(sampleID), path(cna_RDS)
    tuple val(datasetID), val(patientID), val(sampleID), path(snv_RDS)
  
  output:

    tuple val(datasetID), val(patientID), val(sampleID), path("$datasetID/$patientID/$sampleID/TINC/*.rds"), emit: rds
    tuple val(datasetID), val(patientID), val(sampleID), path("$datasetID/$patientID/$sampleID/TINC/*.pdf"), emit: pdf

    script:

    """
    #!/usr/bin/env Rscript

    require(CNAqc)
    require(tidyverse)
    require(TINC)

    res_dir = paste0("$datasetID", "/", "$patientID", "/", "$sampleID", "/QC/TINC")
    dir.create(res_dir)

    all_mutations = readRDS("$snv_RDS")
    samples = names(all_mutations)

    tumor_sample = "$sampleID"
    normal_sample = setdiff(samples, tumor_sample)
    tumor_mutations = all_mutations[[tumor_sample]]\$mutations %>% 
      select(chr, from, to, ref, alt, NV, DP, NR, VAF) %>% 
      rename(t_alt_count = NV, t_ref_count = NR, t_tot_count = DP, t_vaf = VAF)

    normal_mutations = all_mutations[[normal_sample]]\$mutations %>% 
      select(chr, from, to, ref, alt, NV, DP, NR,VAF) %>% 
      rename(n_alt_count = NV, n_ref_count = NR, n_tot_count = DP, n_vaf = VAF)

    input_mut = left_join(tumor_mut, normal_mut, 
      join_by(chr == chr, from == from, to == to, ref == ref, alt == alt)) 

    CNAs = readRDS("$cna_RDS")\$segments
    
    TINC_fit = TINC::autofit(input_mut, cna = CNAs, FAST = FALSE)
    tinc_plot = plot(TINC_fit)
    ggplot2::ggsave(plot = tinc_plot, filename = paste(res_dir, "/TINC_plot.pdf"))
    
    """
}