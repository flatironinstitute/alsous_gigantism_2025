# NO ACTIVITY: AN IMPOSED POLAR FORCE + ELASTICITY OF THE DIRECTOR IN THE EVOLUTION + ELASTIC STRESSES IN THE MOMENTUM BALANCE
import numpy as np 
import dedalus.public as d3
import logging
from scipy.io import savemat, loadmat
logger = logging.getLogger(__name__)
#--------------------------------------------------------------------------------------------------------
# DIMENSIONS, FIELDS, AND OPERATORS 

# Geometry and data type
R = 3*np.pi; 
[Np,Nr] = [128,256]; 
dtype = np.complex128;
timestepper =  d3.RK443; 

# Bases
coords= d3.PolarCoordinates('phi', 'r')
dist  = d3.Distributor(coords, dtype=dtype)
disk  = d3.DiskBasis(coords, shape=(Np, Nr), radius=R, dealias=5/2, dtype=dtype)
(phi,r)= dist.local_grids(disk) 
edge   = disk.edge

# Fields
P = dist.Field(name='P', bases=disk);                        # Pressure
u = dist.VectorField(coords, name='u', bases=disk);          # Fluid Velocity
n = dist.VectorField(coords, name='n', bases=disk);          # Polarity field
Ln= dist.VectorField(coords, name='Ln', bases=disk);         # Laplacian of the polarity field

Q = dist.TensorField((coords,coords), name='Q', bases=disk); # 2nd order Q-tensor (symmetric)
H = dist.TensorField((coords,coords), name='H', bases=disk); # Alignment field

# Identity matrix
I = dist.TensorField((coords,coords), name='I', bases=disk); # Identity matrix 
I['g'][0,0] = 1; I['g'][0,1] = 0; I['g'][1,0] = 0; I['g'][1,1] = 1;

# Define Q_perp
Jm = dist.TensorField((coords,coords), name='Jm', bases=disk); 
Jm['g'][0,0] = 0; Jm['g'][0,1] = 1; Jm['g'][1,0] = -1; Jm['g'][1,1] = 0;
Qp = Q@Jm; n_p = -Jm@n;

# Define the tangential tensor on the edge for anchoring
Tphi = dist.TensorField(coords, name='Tphi',bases=edge); 
Tphi['g'][0,0] = 1;
ephi= dist.VectorField(coords,  name='ef',  bases=edge); 
ephi['g'][0] = 1;

# Tau fields for various variables
tau_P =        dist.Field(name='tau_P');
tau_u = dist.VectorField(coords, name='tau_u',  bases=edge)

tau_n = dist.VectorField(coords, name='tau_n',  bases=edge)
tau_Ln= dist.VectorField(coords, name='tau_Ln', bases=edge)

tau_LQ= dist.TensorField(coords, name='tau_LQ', bases=edge)
tau_Q = dist.TensorField(coords, name='tau_Q',  bases=edge)

# Define lift and dr
lift = lambda A: d3.Lift(A, disk, -1)
dr   = lambda A: d3.radial(d3.grad(A)(r=R))

# Define things for no-stress BC as done by Keaton 
rephi= dist.VectorField(coords, name='ef', bases=disk.radial_basis)
rephi['g'][0] = r
rer  = dist.VectorField(coords, name='er', bases=disk.radial_basis)
rer['g'][1]   = r

# Degine grad operations for BCs
Qgrad = d3.grad(Q);  ugrad = d3.grad(u);  ngrad = d3.grad(n); 
lqgrad= d3.grad(H);  lngrad= d3.grad(Ln);
#-------------------------------------------------------------------------------------------------------- 
# Function for initial conditions   
def init(r,phi):
    np.random.seed(seed=3)
    epsi = phi*0;
    nk   = 12;
    cap  = 1-np.tanh(0.1*(r-0.9*R)); #cap = cap/2;
    #cap = 1.d0;
    for k in range(nk):
        epsi = epsi + 0.20*(0.6*np.cos(phi*k) - np.sin(phi*k) + 0.3*np.sin(r*k))*cap
    return epsi
#----------------------------------------------------------------------------------------
# PARAMETERS FOR THE PROBLEM
 
gamma= 4;   # Friction
alpha= 3;   # Dipole strength 
beta =0.0;  # Odd-stress strength 

dT   = 0.2; # Translational difusion for numerical stability
zeta = 1;   # Alignment strength
swt  = 1;   # Switching reduces mean-field polarity

damp = 50; # Damping of high wavenumber (implicit-explicit damping following Eggers)
dpu  = 50; # Damping for velocity

f0   = 1;   # Swimming speed
#-----------------------------------------------------------------------------------------------------------
# EQUATIONS OF MOTION 
problem = d3.IVP([u, P, n, Ln, Q, H, tau_P, tau_u, tau_n, tau_Q, tau_LQ], namespace=locals())

# Alignment field from nematic elasticity
problem.add_equation(" H-lap(Q) = 0")
problem.add_equation(" Ln-lap(n)= 0")

# Momentum balance
problem.add_equation("-gamma*u - grad(P) + dpu*lap(u) + lift(tau_u) = -div(Q*Trace(Q@H) - Q@H) - alpha*div(n*n - Q) - beta*div(n*n_p - Qp) + dpu*lap(u) + div(Q@Q-Q*Trace(Q@Q))")  # Momentum balance 
problem.add_equation(" div(u) + tau_P  = 0") # Continuity
problem.add_equation(" integ(P)        = 0") # Pressure gauge

# Transport of n
problem.add_equation(" dt(n) - dT*Ln + swt*n  + lift(tau_n) = -u@grad(n) + n@grad(u) - n*Trace(Q@grad(u))  - f0*div(n*n - Q) + 2*zeta*(n@Q-n*Trace(Q@Q))") 

# Transport for Q-tensor
problem.add_equation("dt(Q)  - dT*H           + lift(tau_Q) + lap(lift(tau_LQ)) + damp*lap(H) = -u@grad(Q) + Q@grad(u) + (transpose(grad(u)))@Q  - 2*Q*Trace(Q@grad(u)) + 4*zeta*(Q@Q-Q*Trace(Q@Q)) + damp*lap(H)" ) 

# Boundary condition for velocity
problem.add_equation("(rephi@(rer@ugrad))(r=R) = 0")  # Radial strain rate for u
problem.add_equation("(rer@u)(r=R) = 0")              # Impenetrability

# Boundary condition for Q-tensor
bc = 3;
if (bc == 1):
    problem.add_equation("Q(r=R) = Tphi") # Tangential anchoring
    problem.add_equation("n(r=R) = 0")    # Zero polarity on the boundary

    problem.add_equation("H(r=R) = 0")     # Laplacian of Q
if (bc == 2):
    problem.add_equation("(rer@Q)(r=R) = 0")              # Impenetrability of Q
    problem.add_equation("(rephi@(rer@Qgrad))(r=R) = 0")  # Radial strain
    problem.add_equation("H(r=R)= 0")                     # Laplacian of Q

    problem.add_equation("(rer@n)(r=R) = 0")              # Impenetrability of n
    problem.add_equation("(rephi@(rer@ngrad))(r=R) = 0")  # Radial strain
if (bc == 3):
    problem.add_equation("(rer@Q)(r=R) = 0")              # Impenetrability of Q
    problem.add_equation("(rephi@(rer@Qgrad))(r=R) = 0")  # Radial strain
    problem.add_equation("(rer@H)(r=R) = 0")              # Impenetrability of H
    problem.add_equation("(rephi@(rer@lqgrad))(r=R) = 0") # Radial strain

    problem.add_equation("(rer@n)(r=R) = 0")              # Impenetrability of n
    problem.add_equation("(rephi@(rer@ngrad))(r=R) = 0")  # Radial strain
#-----------------------------------------------------------------------------------------------------------
# # INITIAL CONDITIONS 

# Define the operator for symmetrizing the tensor
Q_sym = (Q + d3.transpose(Q))/2;
Q_trc = Q + (1.0 - d3.Trace(Q))*I/2.0

theta = init(r,phi);
Q['g'][0,0] = np.cos(theta)*np.sin(theta)/3; 
Q['g'][0,1] = (np.sin(theta)+np.cos(theta))/3;  
Q['g'] = Q_sym.evaluate()['g'];
Q['g'] = Q_trc.evaluate()['g'];

n['g'] = 0;
#-----------------------------------------------------------------------------------------------------------
# INITIATE SOLVER AND TIMESTEP

# Initiate solver
solver = problem.build_solver(timestepper)
solver.stop_sim_time = 250;

# Intial dt
delt = 1e-3; 

# Define velocity for CFL condition
cfl = d3.CFL(solver, initial_dt=delt, cadence=10, safety=0.2, max_change=1.5, 
             min_change=0.5, max_dt= 0.1, threshold=0.05)
cfl.add_velocity(u)

# Analysis
snapshots = solver.evaluator.add_file_handler('snapshots', sim_dt= 0.05, max_writes=50)
snapshots.add_task(u, name='u')
snapshots.add_task(n, name='n')
snapshots.add_task(Q, name='Q')

# Sparse saving for making movie
visual = solver.evaluator.add_file_handler('visual', sim_dt= 2, max_writes=1)
visual.add_task(u,   name='u');
visual.add_task(n,   name='n'); 
visual.add_task(Q,   name='Q');



# Main loop
try:
    logger.info('Starting main loop')
    while solver.proceed:
        dt = cfl.compute_timestep()    # Compute dt based on velocity
        solver.step(dt)
        Q['g'] = Q_sym.evaluate()['g'] # Symmetrize the Q-tensor
        Q['g'] = Q_trc.evaluate()['g'] # Symmetrize the Q-tensor
        if (solver.iteration-1) % 10 == 0: # Print logger stats after every 10 iterations/time-steps
            logger.info('Iteration=%i, Time=%e, dt=%e' %(solver.iteration, solver.sim_time, dt))
except:
    logger.error('Exception raised, triggering end of main loop.')
    raise
finally:
    solver.log_stats()

