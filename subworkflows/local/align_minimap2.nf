/*
 * Alignment with MINIMAP2
 */

include { MINIMAP2_INDEX } from '../../modules/nf-core/minimap2/index/main'
include { MINIMAP2_ALIGN } from '../../modules/nf-core/minimap2/align/main'

workflow ALIGN_MINIMAP2 {
    take:
    ch_fastq  // channel: tuple val(meta), path(reads)
    ch_fasta  // channel: path  fasta

    main:
    /*
     * Create genome/transcriptome index
     */
    MINIMAP2_INDEX ( ch_fasta )
    ch_index         = MINIMAP2_INDEX.out.index
    minimap2_version = MINIMAP2_INDEX.out.versions

    /*
     * Map reads with MINIMAP2
     */
    MINIMAP2_ALIGN ( ch_fastq, ch_fasta, params.bam_format, params.cigar_paf_format, params.cigar_bam )
    ch_align_sam = MINIMAP2_ALIGN.out.bam

    emit:
    ch_index
    minimap2_version
    ch_align_sam
}
