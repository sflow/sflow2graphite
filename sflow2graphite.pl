#!/usr/bin/perl -w
use strict;
use POSIX;
use IO::Socket::INET;

my $graphite_server = $ARGV[0] || '127.0.0.1';
my $graphite_port   = $ARGV[1] || 2003;

my %metricNames = (
 "cpu_load_one"            => "load.load_one",
 "cpu_load_five"           => "load.load_five",
 "cpu_load_fifteen"        => "load.load_fifteen",
 "disk_total"              => "disk.total",
 "disk_free"               => "disk.free",
 "disk_partition_max_used" => "disk.part_max",
 "disk_reads"              => "disk.reads",
 "disk_bytes_read"         => "disk.bytes_read",
 "disk_read_time"          => "disk.read_time",
 "disk_writes"             => "disk.writes",
 "disk_bytes_written"      => "disk.bytes_written",
 "disk_write_time"         => "disk.write_time",
 "mem_total"               => "mem.total",
 "mem_free"                => "mem.free",
 "mem_shared"              => "mem.shared",
 "mem_buffers"             => "mem.buffers",
 "mem_cached"              => "mem.cached",
 "swap_total"              => "mem.swap_total",
 "swap_free"               => "mem.swap_free",
 "page_in"                 => "mem.page_in",
 "page_out"                => "mem.page_out",
 "swap_in"                 => "mem.swap_in",
 "swap_out"                => "mem.swap_out",
 "cpu_proc_run"            => "cpu.proc_run",
 "cpu_proc_total"          => "cpu.proc_total",
 "cpu_num"                 => "cpu.num",
 "cpu_speed"               => "cpu.speed",
 "cpu_uptime"              => "cpu.uptime",
 "cpu_user"                => "cpu.user",
 "cpu_nice"                => "cpu.nice",
 "cpu_system"              => "cpu.system",
 "cpu_idle"                => "cpu.idle",
 "cpu_wio"                 => "cpu.wio",
 "cpuintr"                 => "cpu.intr",
 "cpu_sintr"               => "cpu.sintr",
 "cpuinterrupts"           => "cpu.interrupts",
 "cpu_contexts"            => "cpu.contexts",
 "nio_bytes_in"            => "net.bytes_in",
 "nio_pkts_in"             => "net.pkts_in",
 "nio_errs_in"             => "net.errs_in",
 "nio_drops_in"            => "net.drops_in",
 "nio_bytes_out"           => "net.bytes_out",
 "nio_pkts_out"            => "net.pkts_out",
 "nio_errs_out"            => "net.errs_out",
 "nio_drops_out"           => "net.drops_out"
);

my $sock = IO::Socket::INET->new(
       PeerAddr => $graphite_server,
       PeerPort => $graphite_port,
       Proto    => 'tcp'
    );

die "Unable to connect: $!\n" unless ($sock->connected);

open(PS, "/usr/local/bin/sflowtool |") || die "Failed: $!\n";

my $agentIP = "";
my $sourceId = "";
my $now = "";
my $attr = "";
my $value = "";
my %hostNames = ();
while( <PS> ) {
  ($attr,$value) = split;
  if('startDatagram' eq $attr) {
    $now = time;
  } elsif ('agent' eq $attr) {
    $agentIP = $value;
  } elsif ('sourceId' eq $attr) {
    $sourceId = $value;
  } elsif ('hostname' eq $attr) {
    if($sourceId eq "2:1") {
      my ($hn) = split /[.]/, $value;
      $hostNames{$agentIP} = $hn;
    }
  } else {
    my $metric = $metricNames {lc $attr};
    my $hostName = $hostNames{$agentIP};
    if($metric && $hostName) {
        $sock->send("$hostName.$metric $value $now\n");
    }
  }
}

close(PS);
$sock->shutdown(2);