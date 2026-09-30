#!/usr/bin/env python3
# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.
"""FASTA manifest and OrionGeno chunk gather for the OrionGeno subworkflow.

Each predict job renames genes from g1 / g1.t1 and repeats from r1. Gathering
concatenates chunks in FASTA order and renumbers those ids.
"""

import sys


def write_manifest(fasta, output):
    order = 0
    seqid = ""
    length = 0
    with open(fasta, encoding="utf-8", newline="\n") as handle, open(
        output, "w", encoding="utf-8", newline="\n"
    ) as out:
        out.write("order\tseqid\tlength\n")
        for raw in handle:
            line = raw.rstrip("\r\n")
            if line.startswith(">"):
                if seqid:
                    out.write(f"{order}\t{seqid}\t{length}\n")
                    order += 1
                token = line[1:].split()
                seqid = token[0] if token else ""
                length = 0
                continue
            length += len(line)
        if seqid:
            out.write(f"{order}\t{seqid}\t{length}\n")


def manifest_order(path):
    order = {}
    with open(path, encoding="utf-8") as handle:
        header = handle.readline()
        if header.strip().split("\t") != ["order", "seqid", "length"]:
            raise SystemExit(f"bad manifest header: {header!r}")
        index = 0
        for raw in handle:
            line = raw.rstrip("\n")
            if not line:
                continue
            parts = line.split("\t", 2)
            if len(parts) < 2 or not parts[1]:
                raise SystemExit(f"bad manifest line: {line!r}")
            if parts[1] not in order:
                order[parts[1]] = index
            index += 1
    return order


def gtf_value(text, key):
    needle = key + ' "'
    for part in text.split(";"):
        part = part.strip()
        if part.startswith(needle) and part.endswith('"'):
            return part[len(needle):-1]
    return ""


def set_gtf_value(text, key, value):
    needle = key + ' "'
    parts = []
    replaced = False
    for part in text.split(";"):
        raw = part.strip()
        if not raw:
            continue
        if raw.startswith(needle) and raw.endswith('"'):
            parts.append(f'{key} "{value}"')
            replaced = True
        else:
            parts.append(raw)
    if not replaced:
        parts.append(f'{key} "{value}"')
    return "; ".join(parts) + ";"


def gff_value(text, key):
    needle = key + "="
    for part in text.split(";"):
        if part.startswith(needle):
            return part[len(needle):]
    return ""


def map_identifier(value, pairs):
    for old, new in pairs:
        if value == old:
            return new
        if value.startswith(old + "."):
            return new + value[len(old):]
    return value


def set_gff_ids(text, pairs):
    parts = []
    for part in text.split(";"):
        if not part:
            continue
        if part.startswith("ID=") or part.startswith("Parent="):
            key, value = part.split("=", 1)
            parts.append(key + "=" + map_identifier(value, pairs))
        else:
            parts.append(part)
    return ";".join(parts)


def read_rows(path):
    rows = []
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            cols = line.split("\t")
            if len(cols) >= 9:
                rows.append(cols)
    return rows


def parse_gtf_genes(path):
    genes = []
    index = {}
    for cols in read_rows(path):
        if cols[2] == "repeat_region":
            continue
        gene_id = gtf_value(cols[8], "gene_id")
        if not gene_id:
            continue
        if gene_id not in index:
            index[gene_id] = {
                "gene_id": gene_id,
                "seqid": cols[0],
                "start": int(cols[3]),
                "end": int(cols[4]),
                "lines": [],
                "transcripts": [],
            }
            genes.append(index[gene_id])
        gene = index[gene_id]
        if cols[2] == "gene":
            gene["seqid"] = cols[0]
            gene["start"] = int(cols[3])
            gene["end"] = int(cols[4])
        transcript_id = gtf_value(cols[8], "transcript_id")
        if transcript_id and transcript_id not in gene["transcripts"]:
            gene["transcripts"].append(transcript_id)
        gene["lines"].append(cols)
    return genes


def parse_gff_genes(path):
    genes = []
    current = None
    for cols in read_rows(path):
        if cols[2] == "repeat_region":
            continue
        if cols[2] == "gene":
            current = {
                "gene_id": gff_value(cols[8], "ID"),
                "seqid": cols[0],
                "start": int(cols[3]),
                "end": int(cols[4]),
                "lines": [cols],
                "transcripts": [],
            }
            genes.append(current)
            continue
        if current is None:
            continue
        if cols[2] in ("mRNA", "transcript"):
            transcript_id = gff_value(cols[8], "ID")
            if transcript_id and transcript_id not in current["transcripts"]:
                current["transcripts"].append(transcript_id)
        current["lines"].append(cols)
    return genes


def sort_genes(genes, seq_order):
    def key(gene):
        return (
            seq_order.get(gene["seqid"], 10**12),
            gene["start"],
            gene["end"],
            gene["seqid"],
        )

    return sorted(genes, key=key)


def write_genes(genes, output, kind):
    with open(output, "w", encoding="utf-8", newline="\n") as handle:
        if kind == "gff3":
            handle.write("##gff-version 3\n")
        for gene_number, gene in enumerate(genes, start=1):
            new_gene = f"g{gene_number}"
            pairs = [(gene["gene_id"], new_gene)]
            for transcript_number, transcript_id in enumerate(gene["transcripts"], start=1):
                pairs.append((transcript_id, f"g{gene_number}.t{transcript_number}"))
            pairs.sort(key=lambda item: len(item[0]), reverse=True)
            for cols in gene["lines"]:
                if kind == "gtf":
                    text = cols[8]
                    text = set_gtf_value(text, "gene_id", new_gene)
                    transcript_id = gtf_value(cols[8], "transcript_id")
                    if transcript_id:
                        text = set_gtf_value(text, "transcript_id", map_identifier(transcript_id, pairs))
                    cols[8] = text
                else:
                    cols[8] = set_gff_ids(cols[8], pairs)
                handle.write("\t".join(cols) + "\n")


def write_repeats(paths, output, kind, seq_order):
    rows = []
    for path in paths:
        rows.extend(read_rows(path))
    rows = [cols for cols in rows if cols[2] == "repeat_region"]
    rows.sort(
        key=lambda cols: (
            seq_order.get(cols[0], 10**12),
            int(cols[3]),
            int(cols[4]),
            cols[6],
        )
    )
    with open(output, "w", encoding="utf-8", newline="\n") as handle:
        if kind == "gff3":
            handle.write("##gff-version 3\n")
        for number, cols in enumerate(rows, start=1):
            if kind == "gtf":
                cols[8] = f'repeat_id "r{number}";'
            else:
                cols[8] = f"ID=r{number}"
            handle.write("\t".join(cols) + "\n")


def main(argv):
    if len(argv) < 2:
        raise SystemExit("usage: oriongeno_scatter.py manifest|genes|repeats ...")
    command = argv[1]
    if command == "manifest":
        if len(argv) != 4:
            raise SystemExit("usage: oriongeno_scatter.py manifest FASTA OUTPUT")
        write_manifest(argv[2], argv[3])
        return
    if command not in ("genes", "repeats"):
        raise SystemExit(f"unknown command {command}")
    if len(argv) < 5:
        raise SystemExit(f"usage: oriongeno_scatter.py {command} gtf|gff3 MANIFEST OUTPUT [INPUT ...]")
    kind = argv[2]
    if kind not in ("gtf", "gff3"):
        raise SystemExit(f"bad kind {kind}")
    manifest = argv[3]
    output = argv[4]
    inputs = argv[5:]
    seq_order = manifest_order(manifest)
    if command == "genes":
        parser = parse_gtf_genes if kind == "gtf" else parse_gff_genes
        genes = []
        for path in inputs:
            genes.extend(parser(path))
        write_genes(sort_genes(genes, seq_order), output, kind)
        return
    write_repeats(inputs, output, kind, seq_order)


if __name__ == "__main__":
    main(sys.argv)
