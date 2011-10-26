use strict;

package CalendarPluginTests;

use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use strict;
use Foswiki::UI::Save;
use Error qw( :try );
use Foswiki::Plugins::CalendarPlugin::Core;

#initiallly testing parsing of date and and range parsing

sub NOT_new {
    my $self = shift()->SUPER::new( 'CalendarPluginFunctions', @_ );
    return $self;
}

sub NOT_loadExtraConfig {
    my $this = shift;
    $this->SUPER::loadExtraConfig();

    $Foswiki::cfg{Plugins}{CalendarPlugin}{Enabled} = 1;
}

sub NOT_set_up {
    my $this = shift;

    $this->SUPER::set_up();

    $Foswiki::cfg{LocalSitePreferences} = "$this->{users_web}.SitePreferences";
}

=begin tml

---+++ Event Syntax

Events are defined by bullets with the following syntax:

| *Event type* | *Syntax* | *Example* |
| *Single*: | =&nbsp;&nbsp; * dd MMM yyyy - description= | 09 Dec 2002 - Expo |
| *Interval*: | =&nbsp;&nbsp; * dd MMM yyyy - dd MMM yyyy - description= | 02 Feb 2002 - 04 Feb 2002 - Vacation |
| *Yearly*: | =&nbsp;&nbsp; * dd MMM - description= | 05 Jun - Every 5th of June |
|^| =&nbsp;&nbsp; * w DDD MMM - description= | 2 Tue Mar - Every 2nd Tuesday of March |
|^| =&nbsp;&nbsp; * L DDD MMM - description= | L Mon May - The last Monday of May |
|^| =&nbsp;&nbsp; * A dd MMM yyyy - description= | A 20 Jul 1969 - First moon landing%BR%This style will mark anniversaries of an event that occurred on the given date. The description will have " (x)" appended to it, where "x" indicates how many years since the occurence of the first date. The first date is not annotated. |
| *Monthly*: | =&nbsp;&nbsp; * w DDD - description= | 1 Fri - Every 1st Friday of the month |
|^| =&nbsp;&nbsp; * L DDD - description= | L Mon - The last Monday of each month |
|^| =&nbsp;&nbsp; * dd - description= | 14 - The 14th of every month |
| *Weekly*: | =&nbsp;&nbsp; * E DDD - description= | E Wed - Every Wednesday |
| ^ | =&nbsp;&nbsp; * E DDD dd MMM yyyy - description= | E Wed 27 Jan 2005 - Every Wednesday Starting 27 Jan 2005 |
| ^ | =&nbsp;&nbsp; * E DDD dd MMM yyyy - dd MMM yyyy - description= | E Wed 1 Jan 2005 - 27 Jan 2005 - Every Wednesday from 1 Jan 2005 through 27 Jan 2005 (inclusive) |
| *Periodic*: | <nobr> =&nbsp;&nbsp; * En dd MMM yyyy - description= </nobr> | E3 02 Dec 2002 - Every three days starting 02 Dec 2002 |
| ^ | <nobr> =&nbsp;&nbsp; * En dd MMM yyyy - dd MMM yyyy - description= </nobr> | E3 12 Apr 2005 - 31 Dec 2005 - Every three days from 12 Apr 2005 through 31 Dec 2005 (inclusive) |
| *Exception*: | Insert the following between the above syntax and the description:<br /> =X { dd MMM yyyy, dd MMM yyyy - dd MMM yyyy }= | 1 Fri X { 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 } - Every first Friday except on the 01 Dec 2002 and between 06 Dec 2002 and 14 Dec 2002 |


NOTE: and BUG: and SMELL:
   1 when the docco talks about bullets, it does not mean foswiki/tml bullets

=cut 

sub test_dateparse {
    my $self = shift;
    
    #| *Single*: | =&nbsp;&nbsp; * dd MMM yyyy - description= | 09 Dec 2002 - Expo |
    $self->assert_str_equals("09|Dec|2002|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 - test\n"));
    $self->assert_str_equals("09|Dec|1111|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 1111 - test\n"));
    $self->assert_str_equals("09|Dec|1111|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 1111 - test\n"));
    #BUG/FEATURE - means we can't be used for sci-fi? $self->assert_str_equals("09|Dec|11111|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 11111 - test\n"));
    #BUG/FEATURE - means we can't be used for history $self->assert_str_equals("09|Dec|123|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 123 - test\n"));
    #BUG/FEATURE - means we can't be used for history $self->assert_str_equals("09|Dec|0001|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 0001 - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 0 2002 - test\n"));
    #BUG - we're defaulting 0 to '' $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 0 Dec 2002 - test\n"));
    #BUG - we've had multi-line bullets for a long time.$self->assert_str_equals("09|Dec|2002|||test continuation", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 - test\n   continuation\n"));
    #yes, these are single - the &dash separator needs whitespace to function :/
    $self->assert_str_equals("09|Dec|2002|||09 Dec 2003", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 - 09 Dec 2003\n"));
    $self->assert_str_equals("09|Dec|2002|||09 Dec 2003 ", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 - 09 Dec 2003 \n"));
    $self->assert_str_equals("09|Dec|2002|||09 Dec 2003 -", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 - 09 Dec 2003 -\n"));
    $self->assert_str_equals("09|Dec|2002|||", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 - \n"));
    #BUG - not sane, not locale-y either $self->assert_str_equals("09|Dec|2002|||", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 December 2002 - \n"));
    #BUG - case sensitive! $self->assert_str_equals("09|Dec|2002|||", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 dec 2002 - \n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" 1 09 Dec 2002 - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 -\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 -\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002\n"));
    $self->assert_str_equals("09|Dec|2002|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 - test\n"));
    $self->assert_str_equals("09|Dec|2002|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse("  * 09 Dec 2002 - test\n"));
    $self->assert_str_equals("09|Dec|2002|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse("\t\t* 09 Dec 2002 - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse("* 09 Dec 2002 - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * Dec 2002 - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 2002 - test\n"));

    #| *Interval*: | =&nbsp;&nbsp; * dd MMM yyyy - dd MMM yyyy - description= | 02 Feb 2002 - 04 Feb 2002 - Vacation |
    $self->assert_str_equals("09|Dec|2002|09|Dec|2003|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 - 09 Dec 2003 - test\n"));
    $self->assert_str_equals("09|Dec|2002|09|Dec|2003|||", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 - 09 Dec 2003 -\t\n"));
    $self->assert_str_equals("09|Dec|2002|09|Dec|2002|||okok", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec 2002 - 09 Dec 2002 -\tokok\n"));

    #| *Yearly*: | =&nbsp;&nbsp; * dd MMM - description= | 05 Jun - Every 5th of June |
    #|^| =&nbsp;&nbsp; * w DDD MMM - description= | 2 Tue Mar - Every 2nd Tuesday of March |
    #|^| =&nbsp;&nbsp; * L DDD MMM - description= | L Mon May - The last Monday of May |
    #|^| =&nbsp;&nbsp; * A dd MMM yyyy - description= | A 20 Jul 1969 - First moon landing%BR%This style will mark anniversaries of an event that occurred on the given date. The description will have " (x)" appended to it, where "x" indicates how many years since the occurence of the first date. The first date is not annotated. |
    $self->assert_str_equals("09|Dec|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec - test\n"));
    $self->assert_str_equals("09|Dec|||", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec - \n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Dec -\n"));
    $self->assert_str_equals("5|Tue|Dec|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 5 Tue Dec - test\n"));
    #BUG - case sensitive!! $self->assert_str_equals("5|Tue|Dec|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 5 tue Dec - test\n"));
    $self->assert_str_equals("L|Tue|Dec|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * L Tue Dec - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * A Tue Dec - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E Tue Dec - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * X Tue Dec - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * A Tue Dec 2011 - test\n"));
    $self->assert_str_equals("02|Dec|2011|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * A 02 Dec 2011 - test\n"));
    $self->assert_str_equals("2|Dec|2011|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * A 2 Dec 2011 - test\n"));
    $self->assert_str_equals("32|Dec|2011|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * A 32 Dec 2011 - test\n"));
    
    #| *Monthly*: | =&nbsp;&nbsp; * w DDD - description= | 1 Fri - Every 1st Friday of the month |
    #|^| =&nbsp;&nbsp; * L DDD - description= | L Mon - The last Monday of each month |
    #|^| =&nbsp;&nbsp; * dd - description= | 14 - The 14th of every month |
    $self->assert_str_equals("09|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 - test\n"));
    $self->assert_str_equals("09|||", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09  - \n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 -\n"));
    $self->assert_str_equals("5|Tue|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 5 Tue - test\n"));
    #BUG - case sensitive!! $self->assert_str_equals("5|Tue|Dec|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 5 tue - test\n"));
    $self->assert_str_equals("L|Tue|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * L Tue - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * A Tue - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * X Tue - test\n"));
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * A Tue 2011 - test\n"));
    $self->assert_str_equals("02|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 02 - test\n"));
    $self->assert_str_equals("2|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 2 - test\n"));
    $self->assert_str_equals("32|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 32 - test\n"));
    
    #| *Weekly*: | =&nbsp;&nbsp; * E DDD - description= | E Wed - Every Wednesday |
    #| ^ | =&nbsp;&nbsp; * E DDD dd MMM yyyy - description= | E Wed 27 Jan 2005 - Every Wednesday Starting 27 Jan 2005 |
    #| ^ | =&nbsp;&nbsp; * E DDD dd MMM yyyy - dd MMM yyyy - description= | E Wed 1 Jan 2005 - 27 Jan 2005 - Every Wednesday from 1 Jan 2005 through 27 Jan 2005 (inclusive) |
    $self->assert_str_equals("Sat|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E Sat - test\n"));
    $self->assert_str_equals("Sat|27|Jan|2005|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E Sat 27 Jan 2005  - test\n"));
    $self->assert_str_equals("Sat|27|Jan|2005|27|Jan|2005|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E Sat 27 Jan 2005 - 27 Jan 2005 - test\n"));
    $self->assert_str_equals("Sat|27|Jan|2005|27|Jan|2005|||test - more dash", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E Sat 27 Jan 2005 - 27 Jan 2005 - test - more dash\n"));
    
    #| *Periodic*: | <nobr> =&nbsp;&nbsp; * En dd MMM yyyy - description= </nobr> | E3 02 Dec 2002 - Every three days starting 02 Dec 2002 |
    #| ^ | <nobr> =&nbsp;&nbsp; * En dd MMM yyyy - dd MMM yyyy - description= </nobr> | E3 12 Apr 2005 - 31 Dec 2005 - Every three days from 12 Apr 2005 through 31 Dec 2005 (inclusive) |
    $self->assert_null(Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E3 Sat - test\n"));
    $self->assert_str_equals("4|27|Jan|2005|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E4 27 Jan 2005  - test\n"));
    $self->assert_str_equals("5|27|Jan|2005|27|Jan|2005|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E5 27 Jan 2005 - 27 Jan 2005 - test\n"));
    $self->assert_str_equals("6|27|Jan|2005|27|Jan|2005|||test - more dash", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E6 27 Jan 2005 - 27 Jan 2005 - test - more dash\n"));
    $self->assert_str_equals("400|27|Jan|2005|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E400 27 Jan 2005  - test\n"));
    
    #| *Exception*: | Insert the following between the above syntax and the description:<br /> =X { dd MMM yyyy, dd MMM yyyy - dd MMM yyyy }= | 1 Fri X { 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 } - Every first Friday except on the 01 Dec 2002 and between 06 Dec 2002 and 14 Dec 2002 |
    $self->assert_str_equals("13|Dec|2002| X { 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 }| 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 |test - more dash", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 13 Dec 2002 X { 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 } - test - more dash\n"));
    $self->assert_str_equals("Fri| X { 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 }| 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 |test - more dash", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E Fri X { 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 } - test - more dash\n"));
    $self->assert_str_equals("6|27|Jan|2005|27|Jan|2005| X { 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 }| 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 |test - more dash", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * E6 27 Jan 2005 - 27 Jan 2005 X { 01 Dec 2002, 06 Dec 2002 - 14 Dec 2002 } - test - more dash\n"));

#more than one entry
    $self->assert_str_equals("09|Nov|2002|||first\n09|Dec|2002|||test", Foswiki::Plugins::CalendarPlugin::Core::dateparse(" * 09 Nov 2002 - first\n * 09 Dec 2002 - test\n"));

}


1;
__END__
Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2011 SvenDowideit@fosiki.com
I finally got sick of the untestedness of this code - once there are tests, we can think.
GPL3 or later