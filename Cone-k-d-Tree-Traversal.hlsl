//Before using this function, float3 precompute has to be filled according to Tsakok cone-frustum-plane test:
//float3 precompute[2];
//float3 beta = tan(cone.Alpha) * sqrt(1.0f - cone.Direction * cone.Direction);
//precompute[0] = rcp(cone.Direction + beta);
//precompute[1] = rcp(cone.Direction - beta);

bool kdStandardStackBasedTraversal(Cone cone, float tNearClipping, inout TriHit triHits[n], float3 precompute[2]) 
{
    bool hitSomething = false;
    float2 hits; //t_min, t_max in the paper

    if(!RT::IntersectConeFrustumAABB(cone, KDTree.BoundsMin, KDTree.BoundsMax, hits, precompute))
    {
        return false;
    }

    uint currentNode = KDTree.RootNode;
    int todoPos=0;
    KdToDo todoStack[stacksize];									

    while(!IsNullNode(currentNode)) 
    {												
        if(IsInteriorNode(currentNode)) 
        {			
            float splitPos = GetInteriorNode(currentNode).SplitPos;
            int axis = GetInteriorNode(currentNode).SplitAxis;

            float split_minus_origin = splitPos - cone.Origin[axis];

            float temp1 = split_minus_origin * precompute[0][axis];
            float temp2 = split_minus_origin * precompute[1][axis];

            temp1 = (temp1 < 0) ? 1.#INF : temp1;
            temp2 = (temp2 < 0) ? 1.#INF : temp2;

            float t1 = min(temp1, temp2);
            float t2 = max(temp1, temp2);

            uint front, back;
            bool belowFirst = (cone.Origin[axis] < splitPos) || (cone.Origin[axis] == splitPos && cone.Direction[axis] <= 0);

            if (belowFirst)
            {
                front = GetInteriorNode(currentNode).LeftChildPtr;
                back = GetInteriorNode(currentNode).RightChildPtr;
            }
            else
            {
                front = GetInteriorNode(currentNode).RightChildPtr;
                back = GetInteriorNode(currentNode).LeftChildPtr;
            }

            if (t2 < hits[0])
            {														
                currentNode = back;
            }
            else if (t1 > hits[1])
            {						
                currentNode = front;
            }
            else
            {						   
                if(hits[1]>=tNearClipping && max(t1, hits[0])<=triHits[n-1].t) 
                {
                    todoStack[todoPos].NodePtr = back;
                    todoStack[todoPos].tMin = max(t1, hits[0]);
                    todoStack[todoPos].tMax = hits[1];								
                    ++todoPos;
                }

                currentNode = front;
                hits[1] = min(t2, hits[1]);					
            }							
        }
        else  //leaf 
        {							
            IntersectLeafNode(tNearClipping, cone, hitSomething, triHits, GetLeafNode(currentNode));
            
            bool nodeFound = false;
            while(todoPos>0 && !nodeFound) 
            {					
                --todoPos;
                if(todoStack[todoPos].tMax>=tNearClipping && todoStack[todoPos].tMin<=triHits[n-1].t) 
                {
                    hits[0] = todoStack[todoPos].tMin;
                    hits[1] = todoStack[todoPos].tMax; 
                    currentNode = todoStack[todoPos].NodePtr;
                    nodeFound = true;
                }																											
            }

            if(todoPos<=0 && !nodeFound) 
            {
                currentNode = 0xFFFFFFFF;
            }	
        } 																
    }
    
    return hitSomething;			
}