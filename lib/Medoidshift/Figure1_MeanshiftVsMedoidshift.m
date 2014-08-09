x = [randn(2,500) [-4;-0]];

indo = 501;
currPt = x(:,indo);
range = -5:0.1:5;
sigma = 1;

% Create Contour Plot
c1 = 1;
for i = range
    c2 = 1;
    for j = range
        pt = [i j]';
        score = 0;
        for n = 1:size(x,2)
            score = score+ ((i-x(1,n))^2 + (j-x(2,n))^2) * exp(-0.5*((x(1,n)-currPt(1))^2+(x(2,n)-currPt(2))^2)/sigma);
        end

        Score(c1,c2) = score;
        c2 = c2 + 1;
    end
    c1 = c1 + 1;
end

% Compute meanshift vector
w = 0;
newPt = zeros(size(currPt));

for n = 1:size(x,2)
    w = w + exp(-0.5*((x(1,n)-currPt(1))^2+(x(2,n)-currPt(2))^2)/sigma);
    newPt = newPt + x(:,n)*exp(-0.5*((x(1,n)-currPt(1))^2+(x(2,n)-currPt(2))^2)/sigma);
end

newPt = newPt/w;

D       = dist(x).^2;
W       = normpdf(sqrt(D),0,sqrt(sigma));
S       = D*W(:,indo);
[y,I]   = min(S,[],1);
newPt2 = x(:,I);

[X,Y] = meshgrid(range,range);

figure, 
contourf(X,Y,Score/50,15); hold on, colormap(hot);

plot(currPt(2),currPt(1),'ro','MarkerSize',5,'LineWidth',2); hold on,
plot(newPt(2),newPt(1),'b.','MarkerSize',20);
plot(newPt2(2),newPt2(1),'bo','MarkerSize',5,'LineWidth',2);
plot(x(2,:),x(1,:),'.','MarkerSize',10,'Color','y');

title('Contour Plot of Equation 2')
xlabel('Red-Yellow Dot: Current Point | Blue Dot: Meanshift Update | Blue-Yellow Dot: Medoidshift Update');

