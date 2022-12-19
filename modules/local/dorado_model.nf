process DORADO_MODEL {
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.io/nanoporetech/dorado:sha097d9c8abc39b8266e3ee58f531f5ef8944a02c3' :
        'docker.io/nanoporetech/dorado:sha097d9c8abc39b8266e3ee58f531f5ef8944a02c3' }"

    output:
    path model

    script:
    def args = task.ext.args ?: ''

    """
    dorado download \\
        --model ${params.model}
    """

    dorado basecaller \\
        $model
        $folder
        -b ${params.bval}
        --emit-fastq
        -x cuda:0 > dorado_fast.fastq
}


dorado basecaller "/models/dna_r10.4.1_e8.2_400bps_hac@v3.5.2" $PWD/fast5/ \
