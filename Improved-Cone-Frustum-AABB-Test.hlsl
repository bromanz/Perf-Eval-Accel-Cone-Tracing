//Function returns if a cone-frustum hits an AABB. The range is returned in float2 hits. Before using this function, float3 precompute
//has to be filled according to Tsakok cone-frustum-plane test:
//float3 precompute[2];
//float3 beta = tan(cone.Alpha) * sqrt(1.0f - cone.Direction * cone.Direction);
//precompute[0] = rcp(cone.Direction + beta);
//precompute[1] = rcp(cone.Direction - beta);

bool IntersectConeFrustumAABB(Cone cone, float3 aabbMin, float3 aabbMax, out float2 hits, float3 precompute[2]) {
	float tMin = 0.0f;
	float tMax = 1.#INF;

	float3 aabbMin_minus_origin = aabbMin - cone.Origin;
	float3 aabbMax_minus_origin = aabbMax - cone.Origin;

	float3 t0s = aabbMin_minus_origin * precompute[0];
	float3 t1s = aabbMin_minus_origin * precompute[1];
	float3 t2s = aabbMax_minus_origin * precompute[0];
	float3 t3s = aabbMax_minus_origin * precompute[1];

	bool3 t0sNeg = t0s < 0;
	bool3 t1sNeg = t1s < 0;
	bool3 t2sNeg = t2s < 0;
	bool3 t3sNeg = t3s < 0;

	float3 tMinAxisIfNotNeg = min(t0sNeg ? 1.#INF : t0s, min(t1sNeg ? 1.#INF : t1s, min(t2sNeg ? 1.#INF : t2s, t3sNeg ? 1.#INF : t3s)));
	bool3 between = (aabbMin < cone.Origin) && (cone.Origin < aabbMax);
	float3 tMinAxis = between ? 0.0f : tMinAxisIfNotNeg;

	float3 tMaxAxisIfNotNeg = max(t0sNeg ? 0.0f : t0s, max(t1sNeg ? 0.0f : t1s, max(t2sNeg ? 0.0f : t2s, t3sNeg ? 0.0f : t3s)));
	bool3 betweenCond = (!t0sNeg && !t1sNeg) || (!t2sNeg && !t3sNeg);
	float3 tMaxAxis = betweenCond ? tMaxAxisIfNotNeg : 1.#INF;

	tMin = max(tMin, max(tMinAxis[0], max(tMinAxis[1], tMinAxis[2])));
	tMax = min(tMax, min(tMaxAxis[0], min(tMaxAxis[1], tMaxAxis[2])));

	hits[0] = tMin;
	hits[1] = tMax;

	return tMax <= tMin;
}