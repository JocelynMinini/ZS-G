function Y = ZS_fun_trussstructure(X)

% Material properties
e1 = X(1);
e2 = X(2);

a1 = X(3);
a2 = X(4);

p1 = X(5);
p2 = X(6);
p3 = X(7);
p4 = X(8);
p5 = X(9);
p6 = X(10);

% Geometry
nodes = [0 0; 4 0; 8 0; 12 0; 16 0; 20 0; 24 0; 2 2; 6 2; 10 2; 14 2; 18 2; 22 2];
Nodes = createNodes(nodes);

% Loads
dir = [0 -1];
idx = 8:13;
F   = [p1 p2 p3 p4 p5 p6];

for i = 1:length(idx)
    Loads(i) = createLoad(F(i),dir,idx(i));
end

% Beam elements
idx = [
    % Inferior chords
    1, 2; 2, 3; 3, 4; 4, 5; 5, 6; 6, 7;
    % Superior chords
    8, 9; 9, 10; 10, 11; 11, 12; 12, 13;
    % Webs
    1, 8; 8, 2; 2, 9; 9, 3; 3, 10; 10, 4; 4, 11; 11, 5; 5, 12; 12, 6; 6, 13; 13, 7
];


% Chords
for i = 1:11
    Beams(i) = createBeam(idx(i,:),e1,a1,'Chord');
end

% Webs
for i = 12:length(idx)
    Beams(i) = createBeam(idx(i,:),e2,a2,'Web');
end


% Boundary conditions
BC(1,:) = createBC([0 0],1);
BC(2,:) = createBC([1 0],7);

[K, F] = assembleSystem;
U      = solveSystem(K, F);
U      = reshape(U,[2,length(U)/2])';


Y = abs(U(4,2))*1000;
%% Functions

function [K, F] = assembleSystem
    nNodes = length(Nodes);
    K = zeros(2*nNodes);
    F = zeros(2*nNodes, 1);
    
    % Assemble global stiffness matrix
    for k = 1:length(Beams)
        nodeIDs = Beams(k).NodeID;
        dofs = [2*nodeIDs(1)-1, 2*nodeIDs(1), 2*nodeIDs(2)-1, 2*nodeIDs(2)];
        K(dofs, dofs) = K(dofs, dofs) + Beams(k).globalK;
    end
    
    % Assemble force vector
    for k = 1:length(Loads)
        nodeID = Loads(k).NodeID;
        F(2*nodeID-1:2*nodeID) = F(2*nodeID-1:2*nodeID) + Loads(k).F';
    end
end


function [U, R] = solveSystem(K, F)
    nNodes = size(K, 1) / 2;
    freeDofs = ones(2*nNodes, 1);
    
    % Apply boundary conditions
    for k = 1:length(BC)
        nodeID = BC(k).NodeID;
        freeDofs(2*nodeID-1:2*nodeID) = BC(k).BC;
    end
    fixedDofs = find(freeDofs == 0);
    freeDofs  = find(freeDofs == 1);
    
    % Extract the free DOFs submatrix and subvector
    Kff = K(freeDofs, freeDofs);
    Ff = F(freeDofs);
    
    % Check the condition of the matrix
    rcond_value = rcond(Kff);
    
    % Define a threshold for switching to SVD (you may need to adjust this)
    rcond_threshold = 1e-15;
    
    if rcond_value > rcond_threshold
        % Use backslash operator if well-conditioned
        Uf = Kff \ Ff;
    else
        % Use SVD for poorly conditioned matrix
        [U, S, V] = svd(Kff);
        tol = max(size(Kff)) * eps(norm(S));
        r = sum(diag(S) > tol);
        Uf = V(:,1:r) * (U(:,1:r)' * Ff ./ diag(S(1:r,1:r)));
        
        warning('Matrix is poorly conditioned. Using SVD method. RCOND = %e', rcond_value);
    end
    
    % Reconstruct full displacement vector
    U = zeros(2*nNodes, 1);
    U(freeDofs) = Uf;
    
    % Calculate reactions
    R = K * U - F;
end

function out = createNodes(nodes)
    for k = 1:length(nodes)
        out(k).ID = k;
        out(k).XY = nodes(k,:);
    end
end

function out = createBC(bc,idx)
    % 1 for free
    % 0 for fix
    out.BC     = bc;
    out.NodeID = Nodes(idx).ID;
end

function out = createLoad(magnitude,direction,idx)
    out.F      = magnitude * direction;
    out.NodeID = Nodes(idx).ID;
end

function out = createBeam(idx,e,a,type)
    % Type
    out.Ele    = type;
    % Geometry
    out.NodeID = cell2mat({Nodes(idx).ID}');
    out.XY     = cell2mat({Nodes(idx).XY}');
    out.A      = a;
    v          = out.XY(2,:)-out.XY(1,:);
    out.L      = norm(v);
    out.Alpha  = angle(v(1)+1i*v(2))*180/pi;
    % Stiffness
    out.E      = e;
    kLoc       = e*a/out.L * [1 0 -1 0 ; 0 0 0 0 ; -1 0 1 0 ; 0 0 0 0];
    kGlo       = tensorRotate(kLoc,out.Alpha);  
    out.localK  = kLoc;
    out.globalK = kGlo;
end

function newT = tensorRotate(T,theta)
    theta = theta*pi/180;
    TR = [
        cos(theta),  sin(theta), 0,           0;
       -sin(theta),  cos(theta), 0,           0;
        0,           0,          cos(theta),  sin(theta);
        0,           0,         -sin(theta),  cos(theta)
    ];
    newT = TR'*T*TR;
end





end
