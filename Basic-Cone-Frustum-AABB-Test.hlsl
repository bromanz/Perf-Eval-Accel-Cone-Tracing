//Function returns if a cone-frustum hits an AABB. The range is returned in float2 hits. Before using this function, float3 precompute
//has to be filled according to Tsakok cone-frustum-plane test:
//float3 precompute[2];
//float3 beta = tan(cone.Alpha) * sqrt(1.0f - cone.Direction * cone.Direction);
//precompute[0] = rcp(cone.Direction + beta);
//precompute[1] = rcp(cone.Direction - beta);

bool IntersectConeFrustumAABB(Cone cone, float3 aabbMin, float3 aabbMax, out float2 hits, float3 precompute[2])
{
    float tMin = 0.0f;
    float tMax = 1.#INF;

    for (int i = 0; i < 3; i++)
    {
        float4 t;

        //compute parametric distance along cone side to planes
        float split_minus_origin = aabbMin[i] - cone.Origin[i];
        t[0] = split_minus_origin * precompute[0][i];
        t[1] = split_minus_origin * precompute[1][i];

        split_minus_origin = aabbMax[i] - cone.Origin[i];
        t[2] = split_minus_origin * precompute[0][i];
        t[3] = split_minus_origin * precompute[1][i];

        bool4 tNeg = t < 0;

        // Case b1
        if(all(tNeg)) return false;

        float tMinAxis = 1.#INF;
        float tMaxAxis = 0;

        // In between planes
        if (aabbMin[i] < cone.Origin[i] && cone.Origin[i] < aabbMax[i])
        {
            // Hit both planes? (Case a1)
            if ((!tNeg[0] || !tNeg[1]) && (!tNeg[2] || !tNeg[3]))
            {
                continue;
            }
            else
            {
                // Case a2
                tMinAxis = 0;
                for (int j = 0; j < 4; j++)
                {
                    if (!tNeg[j])
                    {
                        tMaxAxis = max(t[j], tMaxAxis);
                    }
                }
            }
        }
        else
        {
            if (!any(tNeg))
            {
                //Case b2
                for (int j = 0; j < 4; j++)
                {
                    tMinAxis = min(t[j], tMinAxis);
                    tMaxAxis = max(t[j], tMaxAxis);
                }
            }
            else
            {
                tMaxAxis = 1.#INF;
                //Case b3
                for (int j = 0; j < 4; j++)
                {
                    if (!tNeg[j])
                    {				
                        tMinAxis = min(t[j], tMinAxis);
                    }
                }
            }
        }

        tMin = max(tMinAxis, tMin); 
        tMax = min(tMaxAxis, tMax);	
	
        if (tMax<=tMin) return false;
    }

    hits[0] = tMin;
    hits[1] = tMax;

    return true;
}