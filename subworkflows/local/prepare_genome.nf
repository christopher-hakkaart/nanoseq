/*
 * Prepare genome/transcriptome before alignment
 */

//include { GET_CHROM_SIZES  } from '../../modules/local/get_chrom_sizes'
include { CUSTOM_GETCHROMSIZES } from '../../modules/nf-core/custom/getchromsizes/main'
include { GTF2BED              } from '../../modules/local/gtf2bed'
include { SAMTOOLS_FAIDX       } from '../../modules/nf-core/modules/samtools/faidx/main'

workflow PREPARE_GENOME {
    take:
    ch_fasta // tuple val(meta), path(fasta)
    ch_gtf   // path gtf

    main:

    /*
     * Make chromosome sizes file
     */
    CUSTOM_GETCHROMSIZES ( ch_reference )
    ch_chrom_sizes = GET_CHROM_SIZES.out.sizes
    ch_fasta_fai = GET_CHROM_SIZES.out.fai
    ch_fasta_gzi = GET_CHROM_SIZES.out.gzi
    getchromsizes_version = GET_CHROM_SIZES.out.versions

    /*
     * Convert GTF to BED12
     */
    GTF2BED ( ch_fasta_gtf )
    ch_gtf_bed = GTF2BED.out.gtf_bed
    gtf2bed_version = GTF2BED.out.versions

    emit:
    ch_chrom_sizes
    ch_fasta_fai
    ch_fasta_gzi
    ch_gtf_bed
    getchromsizes_version
    gtf2bed_version
}
