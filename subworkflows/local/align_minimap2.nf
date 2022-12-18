/*
 * Alignment with MINIMAP2
 */

include { MINIMAP2_INDEX } from '../../modules/nf-core/minimap2/index/main'
include { MINIMAP2_ALIGN } from '../../modules/local/minimap2_align'

workflow ALIGN_MINIMAP2 {
    take:
    ch_fastq          // channel: tuple val(meta), path(reads)
    ch_fasta          // channel: path  fasta
    ch_bed            // channel: path  fbed
    ch_is_transcripts // channel: val boolean

    main:

    ch_versions = Channel.empty()

    /*
     * Create genome/transcriptome index
     */
    MINIMAP2_INDEX (
        [ [:], params.fasta ]
    )
    ch_index    = MINIMAP2_INDEX.out.index
    ch_versions = ch_versions.mix( MINIMAP2_INDEX.out.versions.first() )

    /*
     * Map reads with MINIMAP2
     */
    MINIMAP2_ALIGN (
        ch_fastq,
        ch_fasta,
        ch_bed,
        ch_is_transcripts
    )
    ch_align_sam = MINIMAP2_ALIGN.out.align_sam
    ch_versions  = ch_versions.mix( MINIMAP2_ALIGN.out.versions.first() )


    emit:
    index     = ch_index
    align_sam = ch_align_sam
    versions  = ch_versions
}
