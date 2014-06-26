function R = rot_matrix(u, fi)
% This is just to make it easyer to read!
x = u(1);
y = u(2);
z = u(3);

% Create a 3x3 zero matrix
R = zeros(3,3);
% We use the formula for rotationg matrix about a unit vector u

R(1,1) = cos(fi)+x^2*(1-cos(fi));
R(1,2) = x*y*(1-cos(fi))-z*sin(fi);
R(1,3) = x*z*(1-cos(fi))+y*sin(fi);

R(2,1) = y*x*(1-cos(fi))+z*sin(fi);
R(2,2) = cos(fi)+y^2*(1-cos(fi));
R(2,3) = y*z*(1-cos(fi))-x*sin(fi);

R(3,1) = z*x*(1-cos(fi))-y*sin(fi);
R(3,2) = z*y*(1-cos(fi))+x*sin(fi);
R(3,3) = cos(fi)+z^2*(1-cos(fi));

end