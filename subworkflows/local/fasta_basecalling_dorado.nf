//
// Basecalling with dorado
//

include { DORADO_MODEL      } from '../../modules/local/dorado_model'
include { DORADO_BASECALLER } from '../../modules/local/dorado_basecaller'


workflow FASTA_BASECALLING_DORADO {

    take:
    ch_fast5 // channel: path fast5

    main:

    ch_versions = Channel.empty()

    //
    // Define model options
    //
    def doradoModelList = [
        'dna_r10.4.1_e8.2_260bps_fast@v3.5.2',
        'dna_r10.4.1_e8.2_260bps_fast@v4.0.0',
        'dna_r10.4.1_e8.2_260bps_hac@v3.5.2',
        'dna_r10.4.1_e8.2_260bps_hac@v4.0.0',
        'dna_r10.4.1_e8.2_260bps_sup@v3.5.2',
        'dna_r10.4.1_e8.2_260bps_sup@v4.0.0',
        'dna_r10.4.1_e8.2_400bps_fast@v3.5.2',
        'dna_r10.4.1_e8.2_400bps_fast@v4.0.0',
        'dna_r10.4.1_e8.2_400bps_hac@v3.5.2',
        'dna_r10.4.1_e8.2_400bps_hac@v4.0.0',
        'dna_r10.4.1_e8.2_400bps_sup@v3.5.2',
        'dna_r10.4.1_e8.2_400bps_sup@v4.0.0',
        'dna_r9.4.1_e8_fast@v3.4',
        'dna_r9.4.1_e8_hac@v3.3',
        'dna_r9.4.1_e8_sup@v3.3',
        'rna003_120bps_sup@v3',
        'dna_r10.4.2_e8.2_4khz_stereo@v1.0',
        'dna_r10.4.1_e8.2_260bps_fast@v3.5.2_5mCG@v2',
        'dna_r10.4.1_e8.2_260bps_hac@v3.5.2_5mCG@v2',
        'dna_r10.4.1_e8.2_260bps_sup@v3.5.2_5mCG@v2',
        'dna_r10.4.1_e8.2_400bps_fast@v3.5.2_5mCG@v2',
        'dna_r10.4.1_e8.2_400bps_fast@v4.0.0_5mCG_5hmCG@v2',
        'dna_r10.4.1_e8.2_400bps_hac@v3.5.2_5mCG@v2',
        'dna_r10.4.1_e8.2_400bps_hac@v4.0.0_5mCG_5hmCG@v2',
        'dna_r10.4.1_e8.2_400bps_sup@v3.5.2_5mCG@v2',
        'dna_r10.4.1_e8.2_400bps_sup@v4.0.0_5mCG_5hmCG@v2',
        'dna_r9.4.1_e8_fast@v3.4_5mCG@v0',
        'dna_r9.4.1_e8_hac@v3.4_5mCG@v0',
        'dna_r9.4.1_e8_sup@v3.4_5mCG@v0'
    ]

    if (params.model && doradoModelList.contains(params.model)) {
        ch_modelname = Channel.from( params.model )
    } else {
        exit 1, "Please provide a valid dorado model. Valid options: ${doradoModelList}"
    }

    DORADO_MODEL (
        ch_modelname
    )
    ch_model    = DORADO_MODEL.out.model
    ch_versions = ch_versions.mix( DORADO_MODEL.out.versions.first() )

    DORADO_BASECALLER (
        ch_fast5,
        ch_model
    )
    ch_fastq    = DORADO_BASECALLER.out.fastq
    ch_versions = ch_versions.mix( DORADO_MODEL.out.versions.first() )


    emit:
    versions = ch_versions
}
