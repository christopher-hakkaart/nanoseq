/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowNanoseq.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.fasta ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

// Function to check if running offline
def isOffline() {
    try {
        return NXF_OFFLINE as Boolean
    }
    catch( Exception e ) {
        return false
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Loaded from modules/local/
//
include { GTF2BED         } from '../modules/local/gtf2bed'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { ALIGN_GRAPHMAP2          } from '../subworkflows/local/align_graphmap2'
include { ALIGN_MINIMAP2           } from '../subworkflows/local/align_minimap2'
include { FASTA_BASECALLING_DORADO } from '../subworkflows/local/fasta_basecalling_dorado'
include { INPUT_CHECK              } from '../subworkflows/local/input_check'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_GETCHROMSIZES        } from '../modules/nf-core/custom/getchromsizes/main'
include { FASTQC                      } from '../modules/nf-core/fastqc/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow NANOSEQ {

    ch_versions = Channel.empty()

    // Initialize all file channels

    ch_fasta = Channel.fromPath(params.fasta).ifEmpty(null)
    ch_gtf = Channel.fromPath(params.gtf).ifEmpty(null)

    if(params.input_fast5) {

        ch_fast5 = Channel.fromPath(params.input_fast5)

        //
        // SUBWORKFLOW: Basecalling
        //
        FASTA_BASECALLING_DORADO ( ch_fast5 )
        }

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_fastq    = INPUT_CHECK.out.reads
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_fastq
    )
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique{ it.text }.collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: Get sizes and index fasta
    //
    CUSTOM_GETCHROMSIZES (
        [ [:], params.fasta ]
    )
    ch_sizes    = CUSTOM_GETCHROMSIZES.out.sizes
    ch_versions = ch_versions.mix(CUSTOM_GETCHROMSIZES.out.versions.first().ifEmpty(null))

    ch_is_transcripts = Channel.empty()
    ch_qname          = Channel.empty()

    //
    // MODULE: Convert gtf to bed
    //
    GTF2BED (
        params.gtf
    )
    ch_bed = GTF2BED.out.bed
    ch_versions = ch_versions.mix(GTF2BED.out.versions.first().ifEmpty(null))

    if (params.aligner == 'minimap2') {
        //
        //SUBWORKFLOW: Align fastq files with minimap2
        //
        ALIGN_MINIMAP2 (
            ch_fastq,
            ch_fasta,
            ch_bed,
            ch_is_transcripts
        )
        ch_align_sam = ALIGN_MINIMAP2.out.align_sam
        ch_index     = ALIGN_MINIMAP2.out.index
        ch_versions  = ch_versions.mix(ALIGN_MINIMAP2.out.versions.first().ifEmpty(null))
    } else {
        //
        // SUBWORKFLOW: Align fastq files with graphmap2
        //
        ALIGN_GRAPHMAP2 (
            ch_fastq,
            ch_fasta
        )
        ch_align_sam = ALIGN_GRAPHMAP2.out.align_sam
        ch_index     = ALIGN_GRAPHMAP2.out.index
        ch_versions = ch_versions.mix(ALIGN_GRAPHMAP2.out.version.first().ifEmpty(null))
    }

    //
    // SUBWORKFLOW: Sort and index bam file
    //
    //BAM_SORT_INDEX_SAMTOOLS (
    //    ch_align_sam,   // channel: tuple val(meta), path(input), path(index)
    //    ch_fasta, // channel: path fasta
    //    ch_qname // channel: path qname (optional)
    //)

    //
    // SUBWORKFLOW: Stats
    //
    //BAM_STATS_SAMTOOLS ( bam_sorted, ch_fasta )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowNanoseq.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowNanoseq.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
