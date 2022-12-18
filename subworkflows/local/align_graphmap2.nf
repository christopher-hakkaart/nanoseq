/*
 * Alignment with GRAPHMAP2
 */

include { GRAPHMAP2_INDEX } from '../../modules/nf-core/graphmap2/index/main'
include { GRAPHMAP2_ALIGN } from '../../modules/nf-core/graphmap2/align/main'

workflow ALIGN_GRAPHMAP2 {
    take:
    ch_fastq  // channel: tuple val(meta), path(reads)
    ch_fasta  // channel: path  fasta

    main:

    ch_versions = Channel.empty()

    /*
     * Create genome/transcriptome index
     */
    GRAPHMAP2_INDEX (
        [ params.fasta ]
    )
    ch_index = GRAPHMAP2_INDEX.out.index
    ch_versions = ch_versions.mix(GRAPHMAP2_INDEX.out.versions.first())

    /*
     * Map reads with GRAPHMAP2
     */
    GRAPHMAP2_ALIGN (
        ch_fastq,
        ch_fasta,
        ch_index
    )
    ch_align_sam = GRAPHMAP2_ALIGN.out.sam
    ch_versions = ch_versions.mix(GRAPHMAP2_ALIGN.out.versions.first())


    emit:
    index     = ch_index
    align_sam = ch_align_sam
    versions  = ch_versions
}
