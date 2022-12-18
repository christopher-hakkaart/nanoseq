/*
 * Sort, index BAM file and run samtools stats, flagstat and idxstats
 */

include { SAMTOOLS_VIEW      } from '../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_SORT      } from '../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX     } from '../../modules/nf-core/samtools/index/main'
//include { BAM_STATS_SAMTOOLS } from '../../subworkflows/nf-core/bam_stats_samtools'

workflow BAM_SORT_INDEX_SAMTOOLS {
    take:
    ch_bam   // channel: tuple val(meta), path(input), path(index)
    ch_fasta // channel: path fasta
    ch_qname // channel: path qname (optional)

    main:
    //
    // Module: View file with samtools
    //
    SAMTOOLS_VIEW (
        ch_bam,
        ch_fasta,
        ch_qname
    )
    ch_bam      = SAMTOOLS_VIEW.out.bam
    ch_cram     = SAMTOOLS_VIEW.out.cram
    ch_sam      = SAMTOOLS_VIEW.out.sam
    ch_bai      = SAMTOOLS_VIEW.out.bai
    ch_csi      = SAMTOOLS_VIEW.out.csi
    ch_crai     = SAMTOOLS_VIEW.out.crai
    ch_versions = ch_versions.mix( SAMTOOLS_VIEW.out.versions.first() )

    SAMTOOLS_SORT (
        SAMTOOLS_VIEW.out.bam
    )

    SAMTOOLS_INDEX (
        SAMTOOLS_SORT.out.bam
    )

    SAMTOOLS_SORT.out.bam
        .join(SAMTOOLS_INDEX.out.bai, by: [0])
        .set{ bam_sorted }

    BAM_STATS_SAMTOOLS ( bam_sorted, ch_fasta )

    BAM_STATS_SAMTOOLS.out.stats
        .join ( BAM_STATS_SAMTOOLS.out.idxstats )
        .join ( BAM_STATS_SAMTOOLS.out.flagstat )
        .map  { it -> [ it[1], it[2], it[3] ] }
        .set  { bam_sorted_stats_multiqc }
    samtools_versions = BAM_STATS_SAMTOOLS.out.versions

    emit:
    bam_sorted
    bam_sorted_stats_multiqc
    samtools_versions
}
