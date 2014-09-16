function valid_test_res = validate_results( test_res, min_inl_count )

valid_test_res = test_res;

for i = 1 : length(test_res)
    invalid = valid_test_res{i}.inl_counts < min_inl_count;
    valid_test_res{i}.objnames(invalid) = [];
    valid_test_res{i}.transforms(invalid) = [];
    valid_test_res{i}.inl_counts(invalid) = [];
    valid_test_res{i}.objcount = sum(~invalid);
end

end
