/*
 * Alignment with MINIMAP2
 */

include { MINIMAP2_INDEX          } from '../../modules/local/minimap2_index'
include { MINIMAP2_ALIGN          } from '../../modules/nf-core/minimap2/align/main'

workflow ALIGN_MINIMAP2 {
    take:
    ch_fastq // channel: [ val(meta), [ reads ] ]
    ch_fasta // channel: path fasta

    main:
    /*
     * Create genome/transcriptome index
     */
    MINIMAP2_INDEX ( ch_fasta )
    ch_index         = MINIMAP2_INDEX.out.index
    minimap2_version = MINIMAP2_INDEX.out.versions

    /*
     * Align reads with MINIMAP2
     */
    MINIMAP2_ALIGN ( ch_fastq, ch_index, 'False', 'False', "False" )
    ch_align_bam = MINIMAP2_ALIGN.out.bam

    emit:
    ch_index
    minimap2_version
    ch_align_bam
}
