# Predictive Minimum-Intervention Emergency Corridor Algorithm

### 1. Algorithm Mathematical Pipeline (Steps 1 to 11)

1. **Short-Term Path Prediction**:
   The emergency vehicle's future path is projected over lookahead horizon $T = 30\text{s}$ using velocity $\vec{v}_{amb}$, heading $\theta_{ev}$, and destination bearing:
   $$\vec{P}(t) = \vec{P}_0 + \vec{v}_{amb} \cdot t$$

2. **Spatial Neighborhood Search**:
   Haversine distance filters vehicles within search radius $R = 500\text{m}$.

3. **Path Buffer & Centerline Offset**:
   Calculates longitudinal distance $d_\parallel$ along the path vector and lateral offset $d_\perp$ from path centerline.

4. **Dynamic Obstruction Scoring**:
   $$\text{Score}(v) = 0.35 \cdot \text{ProximityScore} + 0.45 \cdot \text{OverlapScore} + 0.20 \cdot \text{ETAScore}$$
   where $\text{OverlapScore} = 100 \cdot \max\left(0, 1 - \frac{|d_\perp|}{W_{corridor}/2}\right)$. All decisions are calculated dynamically based on geometry; zero hard-coded vehicle rules.

5. **Minimum Intervention Optimization**:
   Minimizes required vehicle movements ($N_{move}$) subject to safety risk $S < S_{max}$ and clearance time $T_{clear} \le \text{ETA}$.

6. **Safety Rules & Feasibility Validation**:
   - **Time Feasibility Limit**: If $\text{ETA} < 3.0\text{s}$, lane shift is unsafe $\implies$ Assign **SLOW DOWN AND KEEP CLEAR**.
   - **Lateral Position Shift**:
     - $d_\perp \le 0.5\text{m} \implies$ **MOVE LEFT WHEN SAFE**
     - $d_\perp > 0.5\text{m} \implies$ **MOVE RIGHT WHEN SAFE**
   - **Opposite Direction**: Heading difference $> 120^\circ \implies$ **NO ALERT**.
   - **Location OFF**: Generates warning notice: *"Precise emergency corridor instructions require location access."* No unsafe lane shift instruction.

7. **Dynamic Recalculation Loop**:
   Automatically re-evaluates state upon telemetry updates without restarting the emergency mission.
