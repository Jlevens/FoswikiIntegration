package ExtensionTable;

# Passed:
#    1 The full $text of an extension topic
#    2 A $marker value for joins of multiple lines into single lines
#       * default \0
#    3 A $kvmarker value when they key of a cell should be part of the value
#      but you need to separate them again later
#       * default \t
#       * E.g. dates/versions in change history are in cell 1, but they are returned as an
#         one {Changes} array for every line of history. The date is not the key it's
#         the date of a line of history
#
# Returns:
#    1 Undef if the table is not found
#    * OR
#    1 A hash ref with the following keys:
#       * _text of the catured table (and only the table)
#          * Multiple lines made single with $marker used to note the joins
#          * The original white space between joins is lost
#          * A multiple line is joined by '\' at the end of line
#             * <br/> as a line-end is also allowed as a toleration of broken-ness in some tables
#             * These can be detected in the returned _text with the regex m/$marker</
#       * Column 1 of each table row
#          * As an array of all the lines with match that key
#          * The key names are standardised or taken as continuation of earlier key, details below
#
# The following standardisation notes are informative only. The exact rules are chosen to provide
# keys and values that match the field names in Extensions/PackageForm. This sub has the responsibilty
# to deal with the vagaries of the Extension Info tables and return the important data.
# (These tables should arguably be cleaned up and standardised in their original topics but that's
# another job entirely.)
#
# Standardised key names (arranged to match PackageForm whenever appropriate):
#
# Key          : 1st column cell needs to contain the following fragment(s)
# -------------:------------------------------------------------------------------------------
# Author       : 'Author' thus matching 'Author(s)', 'Plugin Author' & 'Contrib Author' etc
# Copyright    : 'Copyright'
# Changes      : 'Change' or 'History' - this is also the default for tables that start with a date
#              : indicating a change history entry 
# Dependencies : 'Dependen' thus recognising Dependency or Dependencies and the like
# Development  : 'Develop' or 'Download'
# Home         : 'Home'
# License      : 'License'
# DemoUrl      : 'Demo'
# Perl         : 'Perl'
# Release      : 'Release'
# Version      : 'Version'
# Benchmark    : 'Benchmark'
# SupportUrl   : 'Support' thus recognising 'Support' & 'SupportUrl'
# Tasks        : 'Tasks' or 'Bug'
# 'Other'      : As-is (except removal of all ':', so e.g. 'Appraisal:' is the same as 'Appraisal')

sub parse {
    my ($text, $marker, $kvmarker) = @_;

    # Find & capture the table if possible
    return undef unless $text =~ s/^
        (               # Capture following bit
            \|              # Table start
            [^\|]*?         # Anything not end of table cell
            (?:             # Then one of these phrases (not captured)
            (?<!By,\ )Author|     # Need to ignore 'By, ' as in some topic it what was in a cell that was not an extension table
            Change(\ |&nbsp;)?History|
            Copyright|
            Screenshot|
            (Jan|Feb|Fev|Mar|Apr|May|Mai|Jun|Jul|Aug|Sep|Oct|Okt|Nov|Dec|Dez)\ 20[1-9]\d    # Dates can be changes without an inital 'Changes' key
            )   
            [^\|]*?         # Anything else to end of cell
            \|              # End of cell
            [^\0]*?         # Everything else
        )               # Complete capture
        \z              # To end of text
        //smx;
                                
    $marker //= "\0";
    $kvmarker //= "\t";

    $text = $1;
    my %table;

    $text =~ s/(\\|<br\s*?\/?>)\h*?\n\h*+/$marker\1/g; # Combine continued lines, <br/> to fix some broken topics
                                                       # $marker will allow later reformatting code to re-introduce the breaks

    $text =~ s/^[^\|].*//ms; # Remove lines after table
    $table{_text} = $text;

    my @lines = map { s/\s*?$//g; $_; } split(/\n/, $text );
    
    my $key = 'Changes'; # Some tables start with dates (or other version reference): treat as Change History

    for my $lin ( @lines ) {
        last if $lin !~ m/^\|/;
        my @parts = map { s/^\s*?//g; s/\s*?$//g; $_; } split(/\|/, $lin);
        
        if( $parts[1] =~ m/^(\d|\^|&nbsp;|<|V1\.|XX Mmm 20XX|\.{3}|unrelease|Earlier version|See Subversion|\%DATE\%)/
        ||  $parts[1] eq ''
        ||  $parts[1] =~ m/(Jan|Feb|Fev|Mar(ch)?|Apr|May|Mai|June?|July?|Aug|Sept?(ember)?|Oct|Okt|Nov(ember)?|Dec(ember)?|Dez)\s*?\d{4}/
        )
        { # Continuation of prior key, combine into value 
            $parts[2] = "$parts[1]$kvmarker" . ($parts[2]//'');
            push @{$table{$key}}, @parts[2 .. $#parts];
        }
        else { # Grab key and standardise names
            $key = $parts[1];

            # Standardize the key name            
            $key =~ s/(.*?Dependen.*+)/Dependencies/ms;
            $key =~ s/(.*?Support.*+)/SupportUrl/ms;
            $key =~ s/(.*?(Change|History).*+)/Changes/ms;
            $key =~ s/(.*?(Author|Authos|Maintainer|Modifications made by).*+)/Author/ms;
            $key =~ s/(.*?Copyright.*+)/Copyright/ms;
            $key =~ s/(.*?License.*+)/License/ms;
            $key =~ s/(.*?Home.*+)/Home/ms;
            $key =~ s/(.*?Demo.*+)/DemoUrl/ms;
            $key =~ s/(.*?Release.*+)/Release/ms;
            $key =~ s/(.*?Perl.*+)/Perl/ms; # Before Version check
            $key =~ s/(.*?Java.*+)/Java/ms; # Before Version check
            $key =~ s/(.*?(Version|Dp Syntax Highlighter Ver).*+)/Version/ms;
            $key =~ s/(.*?Benchmark.*+)/Benchmark/ms;
            $key =~ s/(.*?(Develop|Download).*+)/Development/ms;
            $key =~ s/(.*?(Tasks|Bug).*+)/Tasks/ms;
            $key =~ s/://g;  # Anything else as-is remove colons so thinkgs like 'Appraisal:' are taken as 'Appraisal'
            push @{$table{$key}}, @parts[2 .. $#parts];
            push @{$table{_keys}{$key}}, $parts[1]; # Note original keys that matched
        }
    }
    return \%table;
}
1;
