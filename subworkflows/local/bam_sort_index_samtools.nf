/*
 * Sort, index BAM file and run samtools stats, flagstat and idxstats
 */

//include { SAMTOOLS_VIEW_BAM  } from '../../modules/local/samtools_view_bam'
include { SAMTOOLS_SORT      } from '../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX     } from '../../modules/nf-core/samtools/index/main'
include { BAM_STATS_SAMTOOLS } from '../../subworkflows/local/bam_stats_samtools'

workflow BAM_SORT_INDEX_SAMTOOLS {
    take:
    ch_align_bam
    ch_fasta

    main:
    /*
     * Samtools sorta and index
     */
        SAMTOOLS_SORT( ch_align_bam )

        SAMTOOLS_INDEX( SAMTOOLS_SORT.out.bam )

        SAMTOOLS_SORT.out.bam
            .join( SAMTOOLS_INDEX.out.bai )
            .set { ch_bam_bai }

    /*
     * SUBWORKFLOW: Create stats using samtools
     */
    BAM_STATS_SAMTOOLS ( ch_bam_bai, ch_fasta )


    emit:
    ch_bam_bai  = ch_bam_bai
    ch_stats    = BAM_STATS_SAMTOOLS.out.stats       // channel: [ val(meta), [ stats ] ]
    ch_flagstat = BAM_STATS_SAMTOOLS.out.flagstat // channel: [ val(meta), [ flagstat ] ]
    ch_idxstats = BAM_STATS_SAMTOOLS.out.idxstats // channel: [ val(meta), [ idxstats ] ]
    ch_versions = BAM_STATS_SAMTOOLS.out.versions     //    path: version.yml
}
