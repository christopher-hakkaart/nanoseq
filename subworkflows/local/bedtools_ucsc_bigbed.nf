/*
 * Convert BAM to BigBed
 */
include { BEDTOOLS_BAMTOBED   } from '../../modules/nf-core/bedtools/bamtobed/main'
include { UCSC_BED12TOBIGBED  } from '../../modules/nf-core/ucsc_bed12tobigbed'

workflow BEDTOOLS_UCSC_BIGBED {
    take:
    ch_bam_bai // // channel: [ val(meta), [ bam ], [bai] ]

    main:
    /*
     * Map
     */
    ch_bam_bai
        .map{ it -> [ it[0], it[1] ] }
        .set{ ch_bam }

    /*
     * Convert BAM to BED12
     */
    BEDTOOLS_BAMTOBED ( ch_bam )
    ch_bed           = BEDTOOLS_BAMTOBED.out.bed
    ch_bedtools_version = BEDTOOLS_BAMTOBED.out.versions

    /*
     * Convert BED12 to BigBED
     */
    UCSC_BED12TOBIGBED ( ch_bed )
    ch_bigbed = UCSC_BED12TOBIGBED.out.bigbed
    ch_bed12tobigbed_version = UCSC_BED12TOBIGBED.out.versions

    emit:
    ch_bigbed
    ch_bedtools_version
    ch_bed12tobigbed_version
}
