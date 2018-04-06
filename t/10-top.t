#!perl
use strict;
use warnings;

use lib 'lib';
use lib 't';
use helper;
use Test::Deep;

use_ok 'Genesis::Top';


subtest 'kit location' => sub {
	my $tmp = workdir();
	my $again = sub {
		system("rm -rf $tmp/.genesis/kits; mkdir -p $tmp/.genesis/kits");
		system("touch $tmp/.genesis/kits/$_") for (qw/
			foo-1.0.0.tar.gz
			foo-1.0.1.tgz
			foo-0.9.6.tar.gz
			foo-0.9.5.tar.gz
			bar-3.4.5.tar.gz

			not-a-kit-file
			unversioned.tar.gz
			unversioned.tgz
		/);
	};
	my $root = Genesis::Top->new($tmp);

	$again->();
	ok(!$root->has_dev_kit, "roots without dev/ should not report having a dev kit");
	cmp_deeply($root->compiled_kits, {
			foo => {
				'0.9.5' => "$tmp/.genesis/kits/foo-0.9.5.tar.gz",
				'0.9.6' => "$tmp/.genesis/kits/foo-0.9.6.tar.gz",
				'1.0.0' => "$tmp/.genesis/kits/foo-1.0.0.tar.gz",
				'1.0.1' => "$tmp/.genesis/kits/foo-1.0.1.tgz",
			},
			bar => {
				'3.4.5' => "$tmp/.genesis/kits/bar-3.4.5.tar.gz",
			},
		}, "roots should list out all of their compiled kits");

	$again->();
	ok( defined $root->find_kit(foo => '1.0.0'), "test root dir should have foo-1.0.0 kit");
	ok(!defined $root->find_kit(foo => '9.8.7'), "test root dir should not have foo-9.8.7 kit");
	ok(!defined $root->find_kit(quxx => undef), "test root dir should not have any quux kit");
	ok( defined $root->find_kit(foo => '1.0.1'), "roots should recognize .tgz kits");
	ok( defined $root->find_kit(foo => 'latest'), "root should find latest kit versions");
	is($root->find_kit(foo => 'latest')->{version}, '1.0.1', "the latest foo kit should be 1.0.1");
	is($root->find_kit(foo => undef)->{version}, '1.0.1', "an undef version should count as 'latest'");
	ok(!defined $root->find_kit(undef => 'latest'), "kit name should be required if more than one kit exists");
	ok(!defined $root->find_kit(undef => '1.0.0'), "kit name should be requried if more than one kit exists, regardless of version uniqueness");

	$again->();
	system("rm -f $tmp/.genesis/kits/bar-*gz");
	cmp_deeply($root->compiled_kits, {
			foo => {
				'0.9.5' => "$tmp/.genesis/kits/foo-0.9.5.tar.gz",
				'0.9.6' => "$tmp/.genesis/kits/foo-0.9.6.tar.gz",
				'1.0.0' => "$tmp/.genesis/kits/foo-1.0.0.tar.gz",
				'1.0.1' => "$tmp/.genesis/kits/foo-1.0.1.tgz",
			},
		}, "root should only have `foo' kit");
	ok( defined $root->find_kit(undef, 'latest'), "root should find latest kit version of only kit");
	ok( defined $root->find_kit(undef, '0.9.6'), "root should find 0.9.6 kit version of only kit");
	is($root->find_kit(undef, 'latest')->{version}, '1.0.1', "the latest foo kit should be 1.0.1");
	is($root->find_kit(undef, 'latest')->{name}, 'foo', "the only kit should be 'foo'");
	is($root->find_kit(undef, '0.9.6')->{version}, '0.9.6', "specific version of the kit are returned");
	is($root->find_kit(undef, '0.9.6')->{name}, 'foo', "the only kit should be 'foo' (0.9.6)");
};

done_testing;