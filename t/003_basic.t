#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 27;
use Test::Exception;

use Scalar::Util 'isweak';

BEGIN {
    use_ok('Moose');           
}

{
    package BinaryTree;
    use strict;
    use warnings;
    use Moose;

    has 'parent' => (
		is        => 'rw',
		isa       => 'BinaryTree',	
        predicate => 'has_parent',
		weak_ref  => 1,
    );

    has 'left' => (
		is        => 'rw',	
		isa       => 'BinaryTree',		
        predicate => 'has_left',         
    );

    has 'right' => (
		is        => 'rw',	
		isa       => 'BinaryTree',		
        predicate => 'has_right',           
    );

    before 'right', 'left' => sub {
        my ($self, $tree) = @_;
	    $tree->parent($self) if defined $tree;   
	};
	
	sub BUILD {
	    my ($self, %params) = @_;
	    if ($params{parent}) {
	        # yeah this is a little 
	        # weird I know, but I wanted
	        # to check the weaken stuff 
	        # in the constructor :)
	        if ($params{parent}->has_left) {
	            $params{parent}->right($self);	            
	        }
	        else {
	            $params{parent}->left($self);	            
	        }
	    }
	}
}

my $root = BinaryTree->new();
isa_ok($root, 'BinaryTree');

is($root->left, undef, '... no left node yet');
is($root->right, undef, '... no right node yet');

ok(!$root->has_left, '... no left node yet');
ok(!$root->has_right, '... no right node yet');

ok(!$root->has_parent, '... no parent for root node');

my $left = BinaryTree->new();
isa_ok($left, 'BinaryTree');

ok(!$left->has_parent, '... left does not have a parent');

$root->left($left);

is($root->left, $left, '... got a left node now (and it is $left)');
ok($root->has_left, '... we have a left node now');

ok($left->has_parent, '... lefts has a parent');
is($left->parent, $root, '... lefts parent is the root');

ok(isweak($left->{parent}), '... parent is a weakened ref');

my $right = BinaryTree->new();
isa_ok($right, 'BinaryTree');

ok(!$right->has_parent, '... right does not have a parent');

$root->right($right);

is($root->right, $right, '... got a right node now (and it is $right)');
ok($root->has_right, '... we have a right node now');

ok($right->has_parent, '... rights has a parent');
is($right->parent, $root, '... rights parent is the root');

ok(isweak($right->{parent}), '... parent is a weakened ref');

my $left_left = BinaryTree->new(parent => $left);
isa_ok($left_left, 'BinaryTree');

ok($left_left->has_parent, '... left does have a parent');

is($left_left->parent, $left, '... got a parent node (and it is $left)');
ok($left->has_left, '... we have a left node now');
is($left->left, $left_left, '... got a left node (and it is $left_left)');

ok(isweak($left_left->{parent}), '... parent is a weakened ref');

