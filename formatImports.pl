use strict;
use warnings;
use Data::Dumper;
use File::Slurp;

my $numArgs = $#ARGV;
die 'CRASH: Must have a file to work with' unless ( $numArgs == 0 );
my $filePath = $ARGV[0];

#$filePath = '/Users/markbroski/Documents/IOS Projects/iPhone_Redesign/NFCUWorkspace/NFCU-iPhone/NFCU/NFCU-iPad/ColumnChartElementView.m';
die 'CRASH: file does not exist' unless ( -e $filePath );

my $fileContent = read_file($filePath);

my @allLines         = split /\n/, $fileContent;
my @nonImportLines = ();
my @importLines    = ();
foreach (@allLines) {
    if ( $_ =~ /\s*\#import/  ) {
        push @importLines, $_;
    }
    else {
        push @nonImportLines, $_;
    }
}
my @importComponents = ();
foreach (@importLines) {
    my $regex
        = '^(#import)\s*([A-z/".<>+0-9]+)';
    my @components = ( $_ =~ /$regex/ );
    push @importComponents, \@components;
}

#print Dumper \@importComponents;

@importComponents = sort {
    my $firstTest = ${$a}[1] cmp ${$b}[1];
    if ( $firstTest != 0 ) {
        return $firstTest;
    }
    else {
        return ${$a}[1] cmp ${$b}[1];
    }
} @importComponents;




my @finishedImports = ();
foreach (@importComponents
) {
    my $import =  join( ' ', @{$_} );
    push @finishedImports, $import;
}

my $importBlock = join( "\n", @finishedImports );

my $nonImportBlock = join( "\n", @nonImportLines );

$nonImportBlock =~ s|(Copyright.+\n.+\n)|$1$importBlock\n|;

print $nonImportBlock;

write_file( $filePath, $nonImportBlock );

