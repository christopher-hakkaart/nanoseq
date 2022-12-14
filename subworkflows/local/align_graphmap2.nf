/*
 * Alignment with GRAPHMAP2
 */

include { GRAPHMAP2_INDEX } from '../modules/nf-core/graphmap2/index/main'
include { GRAPHMAP2_ALIGN } from '../modules/nf-core/graphmap2/align/main'

workflow ALIGN_GRAPHMAP2 {
    take:
    ch_fastq  // channel: tuple val(meta), path(reads)
    ch_fasta  // channel: path  fasta

    main:
    /*
     * Create genome/transcriptome index
     */
    GRAPHMAP2_INDEX ( ch_fasta )
    ch_index          = GRAPHMAP2_INDEX.out.index

    /*
     * Map reads with GRAPHMAP2
     */
    GRAPHMAP2_ALIGN ( ch_index, ch_fasta, ch_index )
    ch_align_sam = GRAPHMAP2_ALIGN.out.sam
    graphmap2_version = GRAPHMAP2_ALIGN.out.versions

    emit:
    ch_index
    ch_align_sam
    graphmap2_version
}
