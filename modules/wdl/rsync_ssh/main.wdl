# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task rsync_ssh {
  input {
    File input_file
    String user
    String server
    String target_dir
  }

  String prefix = basename(input_file)
  String destination = user + "@" + server + ":" + target_dir + "/" + prefix

  command <<<
    set -euo pipefail

    ssh \
      ~{user}@~{server} \
      mkdir -p ~{target_dir}

    rsync \
      -av \
      ~{input_file} \
      ~{destination}
  >>>

  output {
    String remote_path = destination
  }

  requirements {
    container: "ghcr.io/hillerlab/rsync_ssh:latest"
  }
}

workflow run {
  input {
    File input_file
    String user
    String server
    String target_dir
  }

  call rsync_ssh {
    input:
      input_file = input_file,
      user = user,
      server = server,
      target_dir = target_dir
  }

  output {
    String remote_path = rsync_ssh.remote_path
  }
}
