cwlVersion: v1.0
class: CommandLineTool
baseCommand: cat
inputs:
  file:
    type: File
    inputBinding:
      position: 1
outputs: []
requirements:
  - class: DockerRequirement
    dockerPull: centos:centos7
