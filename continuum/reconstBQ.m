function psi = reconstBQ(t,x)
 % Define the components of B-tensor and the vector
    b11= x(1); b12= x(2); 
    a1 = x(3); a2 = x(4);
    B = [b11 b12;b12 1-b11];

 % Define length: theta = t;
   N = length(t);  
    
% Define the distribution function
    psi = t*0;
    for k = 1:N 
        P = [cos(t(k))^2 sin(t(k))*cos(t(k));sin(t(k))*cos(t(k)) sin(t(k))^2];
        s = tensorprod(B,P,'all');
        psi(k) = exp(s+a1*cos(t(k))+a2*sin(t(k)));
    end
% Define normalization
    Z = trapz(t,psi); psi = psi/Z;
end
    