#!/usr/bin/perl


         use XML::Writer;
         use IO::File;

         my $output = new IO::File(">output.xml");

         my $writer = new XML::Writer(OUTPUT => $output);
         $writer->startTag("greeting",
                           "class" => "simple");
         $writer->characters("Hello, world!");
         $writer->endTag("greeting");
         $writer->end();
         $output->close();

