/*
 * Check input samplesheet and get read channels
 */

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    /*
     * Check samplesheet is valid
     */

    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { get_sample_info(it) }
        .set { reads }

    emit:
    reads                                     // channel: [ val(meta), reads ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, fastq ]
def get_sample_info(LinkedHashMap row) {
    def meta     = [:]
    meta.id      = row.sample
    meta.barcode = row.barcode

    fastq_meta = [ meta, [ file(row.reads) ] ]

    return fastq_meta
}
