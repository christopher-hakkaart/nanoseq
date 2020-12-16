// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process GUPPY {
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process)) }

    if (params.guppy_gpu) {
      container = 'genomicpariscentre/guppy-gpu:4.0.14'
      clusterOptions = params.gpu_cluster_options
    } else {
      container = 'genomicpariscentre/guppy:4.0.14'
    }

    input:
    tuple val(name), path(input_path)
    
    output:
    tuple val(name), path("fastq/*.fastq.gz") , emit: fastq
    path "basecalling/*.txt"                  , emit: summary
    path "basecalling/*"                      , emit: called
    path "*.version.txt"                      , emit: version

    script:
    def barcode_kit  = params.barcode_kit ? "--barcode_kits $params.barcode_kit" : ""
    def barcode_ends = params.barcode_both_ends ? "--require_barcodes_both_ends" : ""
    def proc_options = params.guppy_gpu ? "--device $params.gpu_device --num_callers $task.cpus --cpu_threads_per_caller $params.guppy_cpu_threads --gpu_runners_per_device $params.guppy_gpu_runners" : "--num_callers 2 --cpu_threads_per_caller ${task.cpus/2}"
    def config   = "--flowcell $params.flowcell --kit $params.kit"
    if (params.guppy_config) config = file(params.guppy_config).exists() ? "--config ./$guppy_config" : "--config $params.guppy_config"
    def model    = ""
    if (params.guppy_model)  model  = file(params.guppy_model).exists() ? "--model ./$guppy_model" : "--model $params.guppy_model"
    """
    guppy_basecaller \\
        --input_path $input_path \\
        --save_path ./basecalling \\
        --records_per_fastq 0 \\
        --compress_fastq \\
        $barcode_kit \\
        $proc_options \\
        $barcode_ends \\
        $config \\
       $model
    guppy_basecaller --version &> guppy.version.txt
    
    ## Concatenate fastq files
    mkdir fastq
    cd basecalling
    if [ "\$(find . -type d -name "barcode*" )" != "" ]
    then
        for dir in barcode*/
        do
            dir=\${dir%*/}
            cat \$dir/*.fastq.gz > ../fastq/\$dir.fastq.gz
        done
    else
        cat *.fastq.gz > ../fastq/${name}.fastq.gz
    fi
    """
}
