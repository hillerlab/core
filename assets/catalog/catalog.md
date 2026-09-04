<p align="center">
  <p align="center">
  <picture>
    <source
      media="(prefers-color-scheme: dark)"
      srcset="../figures/hillerlab-dark.png"
    >
    <source
      media="(prefers-color-scheme: light)"
      srcset="../figures/hillerlab-light.png"
    >
    <img
      width="200"
      alt="Hiller Lab"
      src="../figures/hillerlab-light.png"
    >
  </picture>
  </p>

  <span>
    <h1 align="center">
        core
    </h1>
  </span>

  <p align="center">
    <a href="https://github.com/hillerlab/core" target="_blank">
      <img alt="GitHub License" src="https://img.shields.io/github/license/hillerlab/core?color=blue">
    </a>
  </p>

  <p align="center">
    <samp>
        <span> core modules/subworkflows repository for</span>
        <br>
        <span> The Hiller Lab at the Senckenberg Gesellschaft für Naturforschung </span>
        <br>
        <br>
        <a href="https://github.com/hillerlab/core/blob/master/assets/catalog/catalog.md">catalog</a> .
        <a href="https://github.com/hillerlab/containers">containers</a> .
        <a href="https://hillerlab.com/">us</a> 
    </samp>
  </p>

</p>

---

## Genome alignment & comparison (chains/PSL)

- [axtchain](../../modules/nextflow/axtchain/main.nf) — Convert PSL alignments to chains.
- [cat_psl](../../modules/nextflow/cat_psl/main.nf) — Concatenate LASTZ PSL files for one target-partition bucket.
- [cesar2](../../modules/nextflow/cesar2/main.nf) — Realign coding exons or genes to DNA sequences.
- [chaincleaner](../../modules/nextflow/chaincleaner/main.nf) — Remove weak and suspicious chains using chainCleaner.
- [chainfilter](../../modules/nextflow/chainfilter/main.nf) — Filter chains by minimum score and compress the result.
- [chainmergesort](../../modules/nextflow/chainmergesort/main.nf) — Merge per-bundle chain files into a single sorted chain.
- [chainc](../../modules/nextflow/chainc/main.nf) — Remove chain-breaking alignments using chain/net files.
- [chaintools/antirepeat](../../modules/nextflow/chaintools/antirepeat/main.nf) — Remove chains that are primarily the result of repeats.
- [chaintools/compare](../../modules/nextflow/chaintools/compare/main.nf) — Compare exact mappings, coverage, ambiguity, and continuity between two chain files.
- [chaintools/coverage](../../modules/nextflow/chaintools/coverage/main.nf) — Measure annotation feature coverage by aligned chain blocks.
- [chaintools/filter](../../modules/nextflow/chaintools/filter/main.nf) — Filter chains by chain score/target/query.
- [chaintools/merge](../../modules/nextflow/chaintools/merge/main.nf) — Merge chains into a single chain file.
- [chaintools/score](../../modules/nextflow/chaintools/score/main.nf) — Score chains by chain score/target/query.
- [chaintools/sort](../../modules/nextflow/chaintools/sort/main.nf) — Sort chains by chain score/target/query.
- [chaintools/split](../../modules/nextflow/chaintools/split/main.nf) — Split chains into multiple chain files/chunks.
- [chaintools/stats](../../modules/nextflow/chaintools/stats/main.nf) — Summarize alignment, gap, and continuity statistics for a chain file.
- [fill_chainmerge](../../modules/nextflow/fill_chainmerge/main.nf) — Merge filled chain chunks into a single compressed chain.
- [psltools/convert](../../modules/nextflow/psltools/convert/main.nf) — Convert PSL to BED.
- [psltools/filter](../../modules/nextflow/psltools/filter/main.nf) — Filter PSL files by score, strand, or other criteria.
- [psltools/merge](../../modules/nextflow/psltools/merge/main.nf) — Merge PSL files into a single PSL file.
- [psltools/score](../../modules/nextflow/psltools/score/main.nf) — Score PSL files by summing alignment scores.
- [psltools/sort](../../modules/nextflow/psltools/sort/main.nf) — Sort PSL files by chromosome, start, or other criteria.
- [psltools/split](../../modules/nextflow/psltools/split/main.nf) — Split PSL files into multiple PSL files.
- [psltools/stats](../../modules/nextflow/psltools/stats/main.nf) — Get statistics about PSL files.
- [psltools/swap](../../modules/nextflow/psltools/swap/main.nf) — Swap PSL files from reference to query.
- [pslsortacc](../../modules/nextflow/pslsortacc/main.nf) — Sort PSL files by target chromosome using pslSortAcc.
- [repeat_filler](../../modules/nextflow/repeat_filler/main.nf) — Fill gaps in chain alignments using repeat filling.
- [hspz/run](../../modules/nextflow/hspz/run/main.nf) — GPU-accelerated high-scoring ungapped alignment pair backend.
- [kegalign/expand](../../modules/nextflow/kegalign/expand/main.nf) — Unpack a KegAlign package into one job record per partition.
- [kegalign/lastz](../../modules/nextflow/kegalign/lastz/main.nf) — CPU gapped-extension stage for the KegAlign backend.
- [kegalign/mps](../../modules/nextflow/kegalign/mps/main.nf) — Run KegAlign GPU instances concurrently on one GPU via NVIDIA MPS.
- [kegalign/run](../../modules/nextflow/kegalign/run/main.nf) — GPU seeding/ungapped-extension/HSP filtering with KegAlign.

---

## Read alignment & indexing

- [minimap2/align](../../modules/nextflow/minimap2/align/main.nf) — Align long reads to a reference using Minimap2.
- [desalt/align](../../modules/nextflow/desalt/align/main.nf) — Align reads to a genome using deSALT.
- [desalt/index](../../modules/nextflow/desalt/index/main.nf) — Build an index for the deSALT aligner.
- [star/align](../../modules/nextflow/star/align/main.nf) — Align RNA-seq reads to a genome using STAR.
- [star/genomegenerate](../../modules/nextflow/star/genomegenerate/main.nf) — Generate STAR splice-junction-aware genome index from FASTA and GTF.

---

## RNA-seq & splicing prediction

- [star/junctions](../../modules/nextflow/star/junctions/main.nf) — Merge and filter splice junction files from STAR.
- [spliceai/chunk](../../modules/nextflow/spliceai/chunk/main.nf) — Chunk genomic sequences for parallel SpliceAI prediction.
- [spliceai/derive](../../modules/nextflow/spliceai/derive/main.nf) — Derive splice event scores from SpliceAI predictions.
- [spliceai/predict](../../modules/nextflow/spliceai/predict/main.nf) — Predict splice junctions from genomic sequences using SpliceAI.
- [spliceai/publish](../../modules/nextflow/spliceai/publish/main.nf) — Collect and organize SpliceAI output files.
- [aparent/chunk](../../modules/nextflow/aparent/chunk/main.nf) — Chunk genomic regions for parallel APARENT prediction.
- [aparent/predict](../../modules/nextflow/aparent/predict/main.nf) — Predict polyadenylation sites using the APARENT deep learning model.
- [minisplice/download](../../modules/nextflow/minisplice/download/main.nf) — Download MiniSplice model and calibration files.
- [minisplice/predict](../../modules/nextflow/minisplice/predict/main.nf) — Predict splice site scores using MiniSplice.
- [intronic](../../modules/nextflow/intronic/main.nf) — Classify intronic intervals using intronIC.
- [psauron](../../modules/nextflow/psauron/main.nf) — Predict splice sites from PacBio data using Psauron.

---

## Gene annotation

- [annevo/annotation](../../modules/nextflow/annevo/annotation/main.nf) — One-step ANNEVO annotation (prediction + decoding). Prefer the split modules for production.
- [annevo/prediction](../../modules/nextflow/annevo/prediction/main.nf) — ANNEVO nucleotide-level inference (`process_gpu`; CPU if no GPU profile).
- [annevo/decoding](../../modules/nextflow/annevo/decoding/main.nf) — Decode ANNEVO H5 predictions into GFF3 on CPU.
- [subworkflows/annevo](../../subworkflows/annevo/main.nf) — Scatter (none / chromosome / weighted), predict, decode, and gather GFF3.
- [workflows/annevo](../../workflows/annevo/main.nf) — Standalone ANNEVO pipeline. Bundled ANNEVO is non-commercial.
- [tiberius/predict](../../modules/nextflow/tiberius/predict/main.nf) — Tiberius ab initio inference (`process_gpu`; CPU if no GPU profile). Scatter jobs emit GTF only.
- [tiberius/merge](../../modules/nextflow/tiberius/merge/main.nf) — Merge chunk GTFs with merge_annotations.py, restore FASTA order, emit GTF/GFF3 and optional protein/CDS FASTAs.
- [subworkflows/tiberius](../../subworkflows/tiberius/main.nf) — Scatter (none / chromosome / weighted), predict, and merge.
- [workflows/tiberius](../../workflows/tiberius/main.nf) — Standalone Tiberius pipeline.

---

## Transcript assembly & quantification

- [aletsch](../../modules/nextflow/aletsch/main.nf) — Assemble RNA-seq transcripts using Aletsch.
- [stringtie3](../../modules/nextflow/stringtie3/main.nf) — Transcript assembly and quantification for RNA-seq.
- [transmeta](../../modules/nextflow/transmeta/main.nf) — Multi-sample RNA-seq transcript meta-assembly.
- [beaver](../../modules/nextflow/beaver/main.nf) — Bayesian isoform assembly from multiple transcript annotations.

---

## Long-read & IsoSeq transcriptomics

- [bam2gtf](../../modules/nextflow/bam2gtf/main.nf) — Turn a genome-aligned spliced BAM into a transcript GTF, one transcript per primary read.
- [bax2bam](../../modules/nextflow/bax2bam/main.nf) — Convert BAX to BAM format with scraps and subreads.
- [pbbamtofa](../../modules/nextflow/pbbamtofa/main.nf) — Extract PacBio BAM sequences to FASTA format.
- [longread/check](../../modules/nextflow/longread/check/main.nf) — Check long-read chunk BAMs for errors.
- [longread/pbsim3](../../modules/nextflow/longread/pbsim3/main.nf) — Simulate PacBio long reads using PBSIM3.
- [longread/prepare](../../modules/nextflow/longread/prepare/main.nf) — Prepare long-read simulation from BED and transcript-gene annotations.
- [longread/rg](../../modules/nextflow/longread/rg/main.nf) — Canonicalize PBSIM3 subread BAMs as one synthetic PacBio movie.
- [longread/split](../../modules/nextflow/longread/split/main.nf) — Split long-read simulation into chunks.
- [isoseq/cluster2](../../modules/nextflow/isoseq/cluster2/main.nf) — Cluster PacBio IsoSeq reads using isoseq cluster2.
- [isotools/adapter](../../modules/nextflow/isotools/adapter/main.nf) — Detect and remove adapter sequences from long-read alignments.
- [isotools/align](../../modules/nextflow/isotools/align/main.nf) — Select long reads with pass-1 split alignments suggesting splice sites.
- [isotools/cigar](../../modules/nextflow/isotools/cigar/main.nf) — Rescue missed 3' splice junctions by CIGAR matching.
- [isotools/classify/intron](../../modules/nextflow/isotools/classify/intron/main.nf) — Classify intronic intervals using iso-classify.
- [isotools/fusion](../../modules/nextflow/isotools/fusion/main.nf) — Detect gene fusion events using iso-fusion.
- [isotools/intron](../../modules/nextflow/isotools/intron/main.nf) — Detect intron retention events using iso-intron.
- [isotools/nmd](../../modules/nextflow/isotools/nmd/main.nf) — Detect nonsense-mediated decay candidates using iso-nmd.
- [isotools/orphan](../../modules/nextflow/isotools/orphan/main.nf) — Identify orphan transcripts using iso-orphan.
- [isotools/pas](../../modules/nextflow/isotools/pas/main.nf) — Call polyadenylation sites using iso-pas.
- [isotools/segment](../../modules/nextflow/isotools/segment/main.nf) — Filter and segment long-read transcripts using iso-segment.
- [isotools/utr](../../modules/nextflow/isotools/utr/main.nf) — Detect 3'UTR truncation events using iso-utr.
- [deacon/diff](../../modules/nextflow/deacon/diff/main.nf) — Compute differential transcript indexes using Deacon.
- [deacon/filter](../../modules/nextflow/deacon/filter/main.nf) — Filter reads using a Deacon transcript index.
- [deacon/index](../../modules/nextflow/deacon/index/main.nf) — Build a Deacon transcript index from FASTA sequences.
- [deacon/union](../../modules/nextflow/deacon/union/main.nf) — Create a union index from multiple Deacon indexes.
- [flair/transcriptome](../../modules/nextflow/flair/transcriptome/main.nf) — Build a high-confidence isoform annotation directly from an aligned BAM.
- [gstama/addcdsregions](../../modules/nextflow/gstama/addcdsregions/main.nf) — Add CDS regions to a gs-tama BED from parsed ORF BLAST output.
- [gstama/blastpparser](../../modules/nextflow/gstama/blastpparser/main.nf) — Parse ORF BLASTP output into a gs-tama TSV.
- [gstama/filelist](../../modules/nextflow/gstama/filelist/main.nf) — Write a gs-tama file list TSV for downstream steps.
- [gstama/orfseeker](../../modules/nextflow/gstama/orfseeker/main.nf) — Predict open reading frames in a transcript FASTA with gs-tama.
- [pigeon/classify](../../modules/nextflow/pigeon/classify/main.nf) — Classify a prepared query GFF against a prepared reference (SQANTI3-style).
- [pigeon/prepare_models](../../modules/nextflow/pigeon/prepare_models/main.nf) — Sort and index a query transcript GFF for Pigeon classify.
- [pigeon/prepare_reference](../../modules/nextflow/pigeon/prepare_reference/main.nf) — Prepare the reference annotation and genome for Pigeon classification.
- [sqanti3/qc](../../modules/nextflow/sqanti3/qc/main.nf) — Structural QC and classification of collapsed transcript models.
- [talon/annotate](../../modules/nextflow/talon/annotate/main.nf) — Match labelled reads to a TALON database, assigning known/novel transcript models.
- [talon/creategtf](../../modules/nextflow/talon/creategtf/main.nf) — Export the observed transcript annotation from a TALON database.
- [talon/filter](../../modules/nextflow/talon/filter/main.nf) — Select transcript models for the final TALON annotation.
- [talon/initdb](../../modules/nextflow/talon/initdb/main.nf) — Build the TALON SQLite database from a reference annotation.
- [talon/labelreads](../../modules/nextflow/talon/labelreads/main.nf) — Flag reads by trailing genomic As ahead of TALON annotation.
- [transcriptclean](../../modules/nextflow/transcriptclean/main.nf) — Reference-based correction of a splice-aware genome alignment.

---

## ORF & translation prediction

- [xorf/chunk](../../modules/nextflow/xorf/chunk/main.nf) — Split genomic regions and sequences into chunks.
- [xorf/netstart2](../../modules/nextflow/xorf/netstart2/main.nf) — Predict translation initiation sites using neural networks.
- [xorf/rnasamba](../../modules/nextflow/xorf/rnasamba/main.nf) — Classify ORFs as coding or non-coding using RNAsamba.
- [xorf/transaid](../../modules/nextflow/xorf/transaid/main.nf) — Predict translation initiation sites using TransAID.
- [xorf/translationai](../../modules/nextflow/xorf/translationai/main.nf) — Run translational inference (TAI) on ORF predictions.

---

## Genome & annotation manipulation

- [chromsize](../../modules/nextflow/chromsize/main.nf) — Generate chromosome size files from genome FASTA.
- [genomemask/mask](../../modules/nextflow/genomemask/mask/main.nf) — Mask any region of the genome with any nucleotide or random sequence.
- [genomemask/ns](../../modules/nextflow/genomemask/ns/main.nf) — Mask N's in the genome with any nucleotide or random sequence.
- [genomemask/seleno](../../modules/nextflow/genomemask/seleno/main.nf) — Mask selenocysteine codons of the genome.
- [genepred/lint](../../modules/nextflow/genepred/lint/main.nf) — Lint BED/GTF/GFF files.
- [genepred/prune](../../modules/nextflow/genepred/prune/main.nf) — Prune BED/GTF/GFF files.
- [gxf2bed](../../modules/nextflow/gxf2bed/main.nf) — Convert GXF (GFF/GTF) annotations to BED format.
- [bed2gtf](../../modules/nextflow/bed2gtf/main.nf) — Convert BED to GTF.
- [xloci/cds](../../modules/nextflow/xloci/cds/main.nf) — Extract exonic CDS loci from genome using reads.
- [xloci/exon](../../modules/nextflow/xloci/exon/main.nf) — Extract exonic loci from genome using reads.
- [xloci/intron](../../modules/nextflow/xloci/intron/main.nf) — Extract intronic loci from genome using reads.
- [track](../../modules/nextflow/track/main.nf) — Generate UCSC genome browser track database schema files.

---

## Format conversion & tracks

- [bigtools/bedgraphtobigwig](../../modules/nextflow/bigtools/bedgraphtobigwig/main.nf) — Convert BedGraph to BigWig using bigtools.
- [bigtools/bedtobigbed](../../modules/nextflow/bigtools/bedtobigbed/main.nf) — Convert BED files to BigBed format using bigtools.
- [bigtools/bigwigmerge](../../modules/nextflow/bigtools/bigwigmerge/main.nf) — Merge multiple BigWig files using bigtools.
- [ucsc/twobittofa](../../modules/nextflow/ucsc/twobittofa/main.nf) — Convert 2bit files to FASTA format.
- [ucsc/wigtobigwig](../../modules/nextflow/ucsc/wigtobigwig/main.nf) — Convert Wiggle format to BigWig using wigToBigWig.
- [wiggletools/median](../../modules/nextflow/wiggletools/median/main.nf) — Compute median value across multiple BigWig files.

---

## BAM & FASTQ handling

- [bamsplit/chrom](../../modules/nextflow/bamsplit/chrom/main.nf) — Split a BAM file into one output per reference sequence.
- [bamsplit/inspect](../../modules/nextflow/bamsplit/inspect/main.nf) — Describe a BAM file and what a split of it would look like.
- [bamsplit/region](../../modules/nextflow/bamsplit/region/main.nf) — Split a BAM file into one output per annotated region.
- [bamsplit/shard](../../modules/nextflow/bamsplit/shard/main.nf) — Split a BAM file into a fixed number of deterministic shards.
- [bamsplit/tag](../../modules/nextflow/bamsplit/tag/main.nf) — Split a BAM file into one output per auxiliary-tag value.
- [samtools/mergebam](../../modules/nextflow/samtools/mergebam/main.nf) — Merge multiple BAM files into one sorted BAM.
- [samtools/samtobam](../../modules/nextflow/samtools/samtobam/main.nf) — Convert SAM to BAM format and sort.
- [fxsplit](../../modules/nextflow/fxsplit/main.nf) — Split FASTX/FASTQ reads into chunks for parallel processing.

---

## BINSEQ & CBQ

- [bqc/adapter](../../modules/nextflow/bqc/adapter/main.nf) — Remove 3' adapter sequences from CBQ reads.
- [bqc/correct](../../modules/nextflow/bqc/correct/main.nf) — Correct low-quality bases from the other mate of a CBQ pair.
- [bqc/filter](../../modules/nextflow/bqc/filter/main.nf) — Filter CBQ reads against per-read predicates.
- [bqc/segment](../../modules/nextflow/bqc/segment/main.nf) — Split CBQ reads at internal adapter occurrences.
- [bqc/sniff/adapters](../../modules/nextflow/bqc/sniff/adapters/main.nf) — Infer adapter contamination in CBQ reads.
- [bqc/sniff/strand](../../modules/nextflow/bqc/sniff/strand/main.nf) — Infer RNA-seq library strandedness from CBQ reads.
- [bqc/trim](../../modules/nextflow/bqc/trim/main.nf) — Trim CBQ reads by quality, position, Ns or poly tails.
- [bqc/workflow](../../modules/nextflow/bqc/workflow/main.nf) — All-in-one CBQ quality control in a single pass.
- [bqtools/cat](../../modules/nextflow/bqtools/cat/main.nf) — Concatenate multiple BINSEQ files into one.
- [bqtools/decode](../../modules/nextflow/bqtools/decode/main.nf) — Convert BINSEQ files back to FASTQ.
- [bqtools/encode](../../modules/nextflow/bqtools/encode/main.nf) — Encode FASTQ reads into the columnar CBQ format.
- [bqtools/grep](../../modules/nextflow/bqtools/grep/main.nf) — Search BINSEQ records for subsequences or regexes.
- [bqtools/info](../../modules/nextflow/bqtools/info/main.nf) — Show information and statistics about a BINSEQ file.
- [bqtools/qc](../../modules/nextflow/bqtools/qc/main.nf) — FastQC-inspired quality control on a BINSEQ file.
- [bqtools/revcomp](../../modules/nextflow/bqtools/revcomp/main.nf) — Reverse complement BINSEQ sequences.
- [bqtools/split](../../modules/nextflow/bqtools/split/main.nf) — Split a BINSEQ file into per-pattern files.
- [bqtools/verify](../../modules/nextflow/bqtools/verify/main.nf) — Compute an order-independent BINSEQ checksum.
- [deacon-cbq](../../modules/nextflow/deacon-cbq/main.nf) — Filter CBQ reads using a Deacon transcript index.
- [rustar-cbq](../../modules/nextflow/rustar-cbq/main.nf) — STAR-compatible alignment of FASTQ or CBQ reads.

---

## Utilities

- [wget](../../modules/nextflow/wget/main.nf) — Download files from URLs using wget.
- [kingfisher/get](../../modules/nextflow/kingfisher/get/main.nf) — Download SRA runs from the Sequence Read Archive using kingfisher.
- [rsync_ssh](../../modules/nextflow/rsync_ssh/main.nf) — Transfer files to remote server via SSH using rsync.
- [gunzip](../../modules/nextflow/gunzip/main.nf) — Decompress gzipped files using gunzip.
- [choose](../../modules/nextflow/choose/main.nf) — Select fields from text files using the choose CLI.
- [gawk/join](../../modules/nextflow/gawk/join/main.nf) — Concatenate multiple files into one using gawk.
