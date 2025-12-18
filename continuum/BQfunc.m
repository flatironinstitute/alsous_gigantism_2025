function F = BQfunc(x,Qxx,Qxy,nx,ny)
    % Define the components of B-tensor and the vector
    b11= x(1); b12= x(2); 
    a1 = x(3); a2 = x(4);
    B = [b11 b12;b12 1-b11];
    
    % Define theta for integration
    N = 512;
    t = linspace(0,2*pi,N+1); t = t(1:N); 
    
    % Define the distribution function
    psi = t*0;
    for k = 1:N 
        P = [cos(t(k))^2 sin(t(k))*cos(t(k));sin(t(k))*cos(t(k)) sin(t(k))^2];
        s = tensorprod(B,P,'all');
        psi(k) = exp(s+a1*cos(t(k))+a2*sin(t(k)));
    end
    % Definze normalization
    Z = sum(psi);
    
    % Define moments
    q11 = cos(t).^2.*psi; q12= sin(2*t).*psi/2;
    n1  = cos(t).*psi;    n2 = sin(t).*psi;
    
    F(1) = Qxx-sum(q11)/Z; 
    F(2) = Qxy-sum(q12)/Z;
    F(3) = nx -sum(n1)/Z;
    F(4) = ny -sum(n2)/Z;
end