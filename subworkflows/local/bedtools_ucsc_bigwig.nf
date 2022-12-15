/*
 * Convert BAM to BigWig
 */

include { BEDTOOLS_GENOMECOV } from '../../modules/nf-core/bedtools/genomecov/main'                                                                     //include { UCSC_BEDGRAPHTOBIGWIG } from '../../modules/local/ucsc_bedgraphtobigwig'
include { UCSC_BEDGRAPHTOBIGWIG } from '../../modules/nf-core/ucsc/bedgraphtobigwig/main'

workflow BEDTOOLS_UCSC_BIGWIG {
    take:
    ch_sortbam // channel: [ val(meta), [ reads ] ]

    main:
    /*
     * Convert BAM to BEDGraph
     */
    BEDTOOLS_COVERAGE ( ch_sort, ch_sizes, ".bed" )
    ch_bedgraph      = BEDTOOLS_GENOMECOV.out.genomecov
    bedtools_version = BEDTOOLS_GENOMECOV.out.versions

    // BEDTOOLS SORT "bedtools sort > ${meta.id}.bedGraph"

    /*
     * Convert BEDGraph to BigWig
     */
    UCSC_BEDGRAPHTOBIGWIG ( ch_bedgraph, ch_sizes )
    ch_bigwig = UCSC_BEDGRAPHTOBIGWIG.out.bigwig
    bedgraphtobigwig_version = UCSC_BEDGRAPHTOBIGWIG.out.versions

    emit:
    ch_bigwig
    bedtools_version
    bedgraphtobigwig_version
}
