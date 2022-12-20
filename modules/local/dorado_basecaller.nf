process DORADO_BASECALLER {
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.io/nanoporetech/dorado:sha097d9c8abc39b8266e3ee58f531f5ef8944a02c3' :
        'docker.io/nanoporetech/dorado:sha097d9c8abc39b8266e3ee58f531f5ef8944a02c3' }"

    input:
    path folder
    path model

    output:
    path "*", emit: fastq

    script:
    def emitfastq           = (params.emit_fastq)            ? "--emit-fastq" : ""
    def modifiedbases       = (params.modified_bases)        ? "--modified-bases" : ""
    def modifiedbasesmodels = (params.modified_bases_models) ? "--modified-bases-models ${params.modified_bases_models}" : ""
    def emitmoves           = (params.modified_bases)        ? "--emit-moves" : ""

    """
    dorado basecaller \\
        ${model} \\
        ${folder}/ \\
        --device ${params.device} \\
        -n ${params.max_reads} \\
        -b ${params.batch_size} \\
        -c ${params.chunk_size} \\
        -o ${params.overlap} \\
        -r ${params.num_runners} \\
        ${emitfastq} > sample.fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1)
    END_VERSIONS
    """
}

//        ${emitfastq} \\
//        ${modifiedbases} \\
//        ${modifiedbasesmodels} \\
//        ${emitmoves} \\
