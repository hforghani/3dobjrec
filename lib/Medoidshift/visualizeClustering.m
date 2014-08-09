function visualizeClustering(ar_mode,x)
% Function to visualize 2D clustering
% ar_mode: Pointer array to mode
% x:       Dataset

[a,b,ar] = unique(ar_mode);

if(length(a)<64)
    figure, hold on,
    c = lines;
%    markers = ['*','+','x','.','s','o','^','v','o','s','x','.','+','*','^','v','o','s','x','.','+','*','^','v','o','s','x','.','+','*','^','v','o','s','x','.','+','*','^','v'];
    markers = ['............................................................................................']; % Don't ask...

for i = 1:length(x)
        if(size(x,1)==2)
            plot(x(1,i), x(2,i),markers(ar(i)),'Color',c(ar(i),:));
        else
            plot3(x(1,i), x(2,i),x(3,i),markers(ar(i)),'Color',c(ar(i),:));
        end
    end
else
    figure, hold on,

    if(size(x,1)==2)
        plot(x(1,:), x(2,:),'r.');
    else
        plot3(x(1,:), x(2,:),x(3,:),'r.');
    end
end

if(size(x,1)==2)
    plot(x(1,a),x(2,a),'k.','MarkerSize',20)
else
    plot3(x(1,a),x(2,a),x(3,a),'k.','MarkerSize',20)
end

axis equal, box on, grid on;