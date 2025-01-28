{
  writers,
  python3,
}:

writers.writePython3 "snappy-decompress"
  {
    libraries = [ python3.pkgs.cramjam ];
  }
  ''
    import sys
    import cramjam

    input = sys.stdin.buffer.read()
    sys.stdout.buffer.write(bytes(cramjam.snappy.decompress_raw(input[:-1])))
  ''
