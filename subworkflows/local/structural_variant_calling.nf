/*
 * Structural variant calling
 */

include { SNIFFLES                              } from '../../modules/local/sniffles'
include { BCFTOOLS_SORT as SNIFFLES_SORT        } from '../../modules/nf-core/modules/bcftools/sort/main'
include { TABIX_TABIX as SNIFFLES_TABIX_VCF     } from '../../modules/nf-core/modules/tabix/tabix/main'
include { CUTESV                                } from '../../modules/local/cutesv'
include { BCFTOOLS_SORT as CUTESV_SORT          } from '../../modules/nf-core/modules/bcftools/sort/main'
include { TABIX_BGZIP as CUTESV_BGZIP_VCF       } from '../../modules/nf-core/modules/tabix/bgzip/main'
include { TABIX_TABIX as CUTESV_TABIX_VCF       } from '../../modules/nf-core/modules/tabix/tabix/main'


workflow STRUCTURAL_VARIANT_CALLING {

    take:
    ch_view_sortbam
    ch_fasta
    ch_fai

    main:
    ch_sv_calls_vcf     = Channel.empty()
    ch_sv_calls_vcf_tbi = Channel.empty()

    ch_versions         = Channel.empty()

    /*
     * Call structural variants with sniffles
     */
    if (params.structural_variant_caller == 'sniffles') {

        /*
         * Call structural variants with sniffles
         */
        SNIFFLES( ch_view_sortbam )
        ch_versions = ch_versions.mix(SNIFFLES.out.versions)

        /*
         * Sort vcf file with bcftools
         */
        SNIFFLES_SORT( SNIFFLES.out.sv_calls )
        ch_sv_calls_vcf = SNIFFLES_SORT.out.vcf
        ch_versions = ch_versions.mix(SNIFFLES_SORT.out.versions)

        /*
         * Index sniffles vcf.gz
         */
        SNIFFLES_TABIX_VCF( ch_sv_calls_vcf )
        ch_sv_calls_tbi  = SNIFFLES_TABIX_VCF.out.tbi
        ch_versions = ch_versions.mix(SNIFFLES_TABIX_VCF.out.versions)

    } else if (params.structural_variant_caller == 'cutesv') {

        /*
        * Call structural variants with cutesv
        */
        CUTESV( ch_view_sortbam, ch_fasta )
        ch_versions = ch_versions.mix(CUTESV.out.versions)

        /*
         * Sort vcf file with bcftools
         */
        CUTESV_SORT( CUTESV.out.sv_calls )
        ch_sv_calls_vcf = CUTESV_SORT.out.vcf
        ch_versions = ch_versions.mix(CUTESV_SORT.out.versions)

        /*
         * Tabix cutesv vcf.gz
         */
        CUTESV_TABIX_VCF( ch_sv_calls_vcf )
        ch_sv_calls_tbi  = CUTESV_TABIX_VCF.out.tbi
        ch_versions = ch_versions.mix(CUTESV_TABIX_VCF.out.versions)
    }

    emit:
    ch_sv_calls_vcf
    ch_sv_calls_vcf_tbi
    ch_versions
}
