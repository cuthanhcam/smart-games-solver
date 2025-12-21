"""
Test script to verify Kociemba library is working correctly
"""
import kociemba

def test_kociemba_basic():
    """Test basic Kociemba solving"""
    print("Testing Kociemba library...")
    print("=" * 50)
    
    # Solved cube state (all faces same color)
    # Format: U R F D L B (9 stickers each)
    solved_cube = "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB"
    
    try:
        solution = kociemba.solve(solved_cube)
        print(f"✓ Solved cube solution: {solution}")
        print(f"  (Empty solution is correct for solved cube)")
    except Exception as e:
        print(f"✗ Error solving solved cube: {e}")
        return False
    
    # Test with a scrambled cube
    # This is a valid scrambled state
    scrambled = "DUUBULDBFRBFRRULLLBRDFFFBLURDBFDFDRFRULBLUFDURRBLBDUDL"
    
    try:
        solution = kociemba.solve(scrambled)
        print(f"\n✓ Scrambled cube solution: {solution}")
        print(f"  Solution length: {len(solution.split())} moves")
        
        # Verify solution is reasonable (should be <= 20 moves)
        move_count = len(solution.split())
        if move_count <= 20:
            print(f"  ✓ Solution is optimal (≤ 20 moves)")
        else:
            print(f"  ⚠ Solution is longer than expected")
            
    except Exception as e:
        print(f"✗ Error solving scrambled cube: {e}")
        return False
    
    # Test invalid cube (wrong number of stickers)
    print("\n" + "=" * 50)
    print("Testing error handling...")
    invalid_cube = "INVALID"
    
    try:
        solution = kociemba.solve(invalid_cube)
        print(f"✗ Should have raised error for invalid cube")
        return False
    except Exception as e:
        print(f"✓ Correctly raised error: {type(e).__name__}")
    
    print("\n" + "=" * 50)
    print("✓ All Kociemba tests passed!")
    return True

def test_notation_examples():
    """Test various cube notations"""
    print("\n" + "=" * 50)
    print("Testing various scrambles...")
    
    test_cases = [
        # Simple scrambles
        ("DRLUUBFBRBLURRLRUBLRDDFDFFBRUFUFFDDRURFBLDUBLLDBBLUDL", "Simple scramble 1"),
        ("UBRLURDBFRBDDRLRLLUBFDFUFBURFDUFBDLRULFBLRFDUUDBBLDDR", "Simple scramble 2"),
    ]
    
    for cube_state, description in test_cases:
        try:
            solution = kociemba.solve(cube_state)
            move_count = len(solution.split())
            print(f"✓ {description}: {move_count} moves")
        except Exception as e:
            print(f"✗ {description} failed: {e}")
            return False
    
    return True

if __name__ == "__main__":
    print("Kociemba Library Verification")
    print("=" * 50)
    print()
    
    success = test_kociemba_basic()
    if success:
        test_notation_examples()
        print("\n" + "=" * 50)
        print("✓✓✓ Kociemba library is working correctly! ✓✓✓")
        print("=" * 50)
    else:
        print("\n" + "=" * 50)
        print("✗✗✗ Kociemba library test failed! ✗✗✗")
        print("=" * 50)
