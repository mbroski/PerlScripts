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
my @nonPropertyLines = ();
my @propertyLines    = ();
foreach (@allLines) {
    if ( $_ =~ /\s*\@property/ && $_ !~ /\^/ ) {
        push @propertyLines, $_;
    }
    else {
        push @nonPropertyLines, $_;
    }
}
my @propertyComponents = ();

#      0              1           2              3        4        5                    6
# @property (assign,nonatomic) IBOutlet  UIViewController *  viewController;     //!< Description
foreach (@propertyLines) {
    my $regex
        = '^(\s*\@property)(\s*\([^)]+\))(\s*IBOutlet[\(\)\w]*)?(\s*(?:\w+|id\s*<\w+>))(\s*\*?)(\s*\w+\s*;)(.*)';
    my @components = ( $_ =~ /$regex/ );
    while ( my ( $i, $el ) = each @components ) {
        if ( $el && $i < 6 ) {
            $components[$i] =~ s/\s+//g;
        }
        elsif ( $el && $i == 6 ) {
            $components[$i] =~ s/^\s+//;
        }
        elsif ( !$el && $i < 6 ) {
            $components[$i] = '';
        }
        elsif ( !$el && $i == 6 ) {
            $components[$i] = ' //!< Description';
        }
    }
    push @propertyComponents, \@components;
}

#sort those property qualifiers
foreach (@propertyComponents) {
    my $qualifier = ${$_}[1];
    my $regex     = '(?<=\()([^,]+),([^)]+)';
    $qualifier =~ m/$regex/;
    my @items = ( $1, $2 );
    if ($items[0] ne 'nonatomic'){
        @items = reverse @items;
    }
    ${$_}[1] = "($items[0],$items[1])";
    
}

@propertyComponents = sort {
    my $firstTest = ${$a}[3] cmp ${$b}[3];
    if ( $firstTest != 0 ) {
        return $firstTest;
    }
    else {
        return ${$a}[5] cmp ${$b}[5];
    }
} @propertyComponents;

my @maxSize = ( 0, 0, 0, 0, 0, 0, 0 );
for ( my $i = 0; $i < 6; $i++ ) {
    my $currentMax = $maxSize[$i];
    foreach (@propertyComponents) {
        my $elem = $_->[$i];
        my $len  = length $elem;
        if ( $len > $currentMax ) {
            $currentMax = $len;
        }
    }
    $maxSize[$i] = $currentMax;

}
my $sp = ' ';
for ( my $i = 0; $i < 7; $i++ ) {
    my $maxSize = $maxSize[$i];
    foreach (@propertyComponents) {
        my $elem = $_->[$i];
        my $len  = length $elem;

        my $padding = $maxSize - $len + 1;
        if ( $i ~~ [3] ) {
            $padding--;
            ${$_}[$i] = ( $sp x $padding ) . $elem;
        }
        elsif ( $i ~~ [ 0, 1, 2,  5, 6 ] ) {
            ${$_}[$i] = $elem . ( $sp x $padding );
        }
        elsif ( $i ~~ [4] ) {
            if ( $len > 0 ) {
                ${$_}[$i] = $sp . $elem;
            }
            else { 
                ${$_}[$i] = $sp . $sp . $elem; 
            }
        }
    }

}

my @finishedProperties = ();
foreach (@propertyComponents) {
    my $property = ( $sp x 4 ) . join( '', @{$_} );

    push @finishedProperties, $property;
}

my $propertyBlock = join( "\n", @finishedProperties ) . "\n";

my $nonPropertiesBlock = join( "\n", @nonPropertyLines );

my $regex = '@interface.+?(?=@end)';
$nonPropertiesBlock =~ m/$regex/sx;
my $insertPoint = $+[0];

substr $nonPropertiesBlock, $insertPoint, 0, $propertyBlock;

print $nonPropertiesBlock;

write_file( $filePath, $nonPropertiesBlock );

