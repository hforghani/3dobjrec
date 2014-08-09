function score = graph_match_score(x, M)

score = [];

if length(size(M)) == 2
    score = x' * M * x;
elseif length(size(M)) == 3
    score = 0;
    for i = 1 : length(x)
        score = score + x' * M(:,:,i) * x * x(i);
    end
    if x ~= 0
        score = score / (norm(x) ^ 3);
    end
end

end
