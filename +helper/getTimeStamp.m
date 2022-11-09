function ts = getTimeStamp()
ti = clock;
ts = sprintf('%04d-%02d-%02d-%02dh-%02dm-%02ds',ti(1),ti(2),ti(3),ti(4),ti(5),ceil(ti(6)));
