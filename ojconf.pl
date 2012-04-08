%Config = (
    files => '*_work.txt',
    ivowels => q/(yi|iy|i)/,
    evowels => q/(ye|ey|e)/,
    ovowels => q/(wo|ö|o)/,
    ## Color codes are 30 (black), 31 (red), 32 (green), 33 (yellow),
    ##   34 (blue), 35 (magenta), 36 (cyan), 37 (white)
    color => 32,
    jukugolen => 4,
);

1;
__END__
