/*
 * Convert BAM to BigWig
 */

include { BEDTOOLS_GENOMECOV    } from '../../modules/nf-core/bedtools/genomecov/main'
include { UCSC_BEDGRAPHTOBIGWIG } from '../../modules/local/ucsc_bedgraphtobigwig'

workflow BEDTOOLS_UCSC_BIGWIG {
    take:
    ch_bam_bai // channel: [ val(meta), [ bam ], [bai] ]

    main:
    ch_bam_bai
        .map{ it -> [ it[0], it[1], 1 ] }
        .set{ ch_bam }


    //tuple val(meta), path(intervals), val(scale)
    //path  sizes
    //val   extension
    ch_dummy_file = file("$projectDir/assets/dummy_file.txt", checkIfExists: true)

    /*
     * Convert BAM to BEDGraph
     */
    BEDTOOLS_GENOMECOV ( ch_bam, ch_dummy_file, "bedGraph" )
    ch_bedgraph      = BEDTOOLS_GENOMECOV.out.genomecov
    bedtools_version = BEDTOOLS_GENOMECOV.out.versions

    /*
     * Convert BEDGraph to BigWig
     */
    //UCSC_BEDGRAPHTOBIGWIG ( ch_bedgraph )
    //ch_bigwig = UCSC_BEDGRAPHTOBIGWIG.out.bigwig
    //bedgraphtobigwig_version = UCSC_BEDGRAPHTOBIGWIG.out.versions

    emit:
    ch_bedgraph
    //ch_bigwig
    bedtools_version
    //bedgraphtobigwig_version
}
