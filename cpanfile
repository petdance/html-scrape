# Validate with cpanfile-dump
# https://metacpan.org/release/Module-CPANfile

requires 'File::Spec' => 0;

on 'test' => sub {
    requires 'Test::More' => '0.88';
    requires 'Test::Warnings' => '0';
};
