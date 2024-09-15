namespace Benchmark
{
    using System;
    using System.Diagnostics;
    using System.Text;
    using Benchmark.Imported;
    using Benchmark.Imported.Cryptography;

    internal class Program
    {
        private const int SingleBufferLength = 64 * 1024;
        private static readonly CSharpSHA256 _sha = new CSharpSHA256(true);
        private static readonly byte[] _content;
        private static bool _Buffered;
        private static readonly StringBuilder Output = new StringBuilder();

        static Program()
        {
            _content = new byte[SingleBufferLength];
            XorShiftRandom.FillByteArray(_content, 42);
        }


        private static void Write(string text)
        {
            if (_Buffered)
                Output.Append(text);
            else
                Console.Write(text);
        }

        private static void Main(string[] args)
        {
            string arg0 = args != null && args.Length > 0 ? args[0].ToLower() : null;
            _Buffered = arg0 == "--buffered" || arg0 == "-b";


            Write("Benchmark MB/s:");
            Perform(1);
            int total = 4;
            float sum = 0;
            for (int i = 1; i <= total; i++)
            {
                float bytesPerSecond = Perform(666);
                sum += bytesPerSecond;
                string valueAsString = string.Format("{0:n1}", bytesPerSecond / 1024 / 1024);
                int formatLength = valueAsString.Length + 2;
                Write(" " + valueAsString);
            }

            float avg = sum / total;
            Write(", avg " + string.Format("{0:n1}", avg / 1024 / 1024));

            if (_Buffered)
                Console.WriteLine(Output);
            else
                Console.WriteLine();
        }

        private static float Perform(long durationMs)
        {
            Stopwatch sw = Stopwatch.StartNew();
            long milliSeconds;
            int n = 0;
            do
            {
                int hash = _sha.ComputeHash(_content).Length;
                n++;
                milliSeconds = sw.ElapsedMilliseconds;
            } while (milliSeconds <= durationMs);

            float bytesPerSecond = 1000f * n * SingleBufferLength / milliSeconds;
            return bytesPerSecond;
        }
    }
}namespace Benchmark.Imported
{
    using System;

    public static class XorShiftRandom
    {
        public static void FillByteArray(byte[] bytes)
        {
            ulong seed = (ulong)new Random().Next(int.MaxValue - 1);
            FillByteArray(bytes, seed);
        }

        public static unsafe void FillByteArray(byte[] bytes, ulong seed)
        {
            if (bytes.Length == 0)
                return;

            ulong x_ = seed << 1;
            ulong y_ = seed >> 1;
            int next;
            ulong temp_x, temp_y;

            int* ptr;
            int count = bytes.Length;
            fixed (byte* ptrFrom = &bytes[0])
            {
                ptr = (int*)ptrFrom;
                while (count >= 4)
                {
                    temp_x = y_;
                    x_ ^= x_ << 23;
                    temp_y = x_ ^ y_ ^ (x_ >> 17) ^ (y_ >> 26);
                    next = (int)(temp_y + y_);
                    x_ = temp_x;
                    y_ = temp_y;

                    *ptr++ = next;
                    count -= 4;
                }
            }

            if (count > 0)
            {
                // Never goes here for disk benchmark
                byte* ptrByte = (byte*)ptr;

                x_ ^= x_ << 23;
                temp_y = x_ ^ y_ ^ (x_ >> 17) ^ (y_ >> 26);
                next = (int)(temp_y + y_);

                while (count-- > 0)
                {
                    *ptrByte++ = (byte)(next & 0xFF);
                    next = next >> 8;
                }
            }
        }
    }
}//
// System.Buffer.cs
//
// Authors:
//   Paolo Molaro (lupus@ximian.com)
//   Dan Lewis (dihlewis@yahoo.co.uk)
//
// (C) 2001 Ximian, Inc.  http://www.ximian.com
//

//
// Copyright (C) 2004 Novell, Inc (http://www.novell.com)
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

namespace Benchmark.Imported.Cryptography
{
    using System;
    using System.Runtime.CompilerServices;

    public static class ByteBuffer
    {
#if NETCOREAPP
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
#endif
        public static unsafe void BlockCopy_Unsafe(byte[] src, int srcOffset, byte[] dest, int destOffset, int count)
        {
            ValidateArguments(src, srcOffset, dest, destOffset, count);

            fixed (byte* argSrc = &src[0])
            fixed (byte* argDest = &dest[0])
            {
                byte* ptrSrc = argSrc + srcOffset;
                byte* ptrDest = argDest + destOffset;

                while (count >= 8)
                {
                    *(long*)ptrDest = *(long*)ptrSrc;
                    ptrSrc += 8;
                    ptrDest += 8;
                    count -= 8;
                }

                while (count-- > 0)
                    *ptrDest++ = *ptrSrc++;
            }
        }

#if NETCOREAPP
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
#endif
        public static void BlockCopy_Slow(byte[] src, int srcOffset, byte[] dest, int destOffset, int count)
        {
            ValidateArguments(src, srcOffset, dest, destOffset, count);

            for (int i = 0; i < count; i++) dest[destOffset + i] = src[srcOffset + i];
        }

#if NETCOREAPP
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
#endif
        private static void ValidateArguments(byte[] src, int srcOffset, byte[] dest, int destOffset, int count)
        {
            if (src == null)
                throw new ArgumentNullException("src");

            if (dest == null)
                throw new ArgumentNullException("dest");

            if (srcOffset < 0)
                throw new ArgumentOutOfRangeException("srcOffset",
                    "Non-negative number required.");

            if (destOffset < 0)
                throw new ArgumentOutOfRangeException("destOffset",
                    "Non-negative number required.");

            if (count < 0)
                throw new ArgumentOutOfRangeException("count",
                    "Non-negative number required.");

            if (srcOffset > src.Length - count || destOffset > dest.Length - count)
                throw new ArgumentException(
                    "Offset and length were out of bounds for the array or count is greater than" +
                    "the number of elements from index to the end of the source collection.");
        }
    }
}namespace Benchmark.Imported.Cryptography
{
    using System.Runtime.CompilerServices;
    using System.Security.Cryptography;

    //
// System.Security.Cryptography SHA256Managed Class implementation
//
// Author:
//   Matthew S. Ford (Matthew.S.Ford@Rose-Hulman.Edu)
//
// (C) 2001 
// Copyright (C) 2004, 2005 Novell, Inc (http://www.novell.com)
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//


    public class CSharpSHA256 : SHA256
    {
        private const int BLOCK_SIZE_BYTES = 64;
        private const int HASH_SIZE_BYTES = 32;
        private readonly uint[] _H;
        private readonly byte[] _ProcessingBuffer; // Used to start data when passed less than a block worth.
        private readonly uint[] buff;

        private readonly bool Unsafe;
        private int _ProcessingBufferCount; // Counts how much data we have stored that still needs processed.
        private ulong count;
        private uint[] K;

        public CSharpSHA256(bool @unsafe) : this()
        {
            Unsafe = @unsafe;
        }

        public CSharpSHA256()
        {
            _H = new uint [8];
            _ProcessingBuffer = new byte [BLOCK_SIZE_BYTES];
            buff = new uint[64];
            Initialize();
        }

        private uint Ch(uint u, uint v, uint w)
        {
            return (u & v) ^ (~u & w);
        }

        private uint Maj(uint u, uint v, uint w)
        {
            return (u & v) ^ (u & w) ^ (v & w);
        }

        private uint Ro0(uint x)
        {
            return ((x >> 7) | (x << 25))
                   ^ ((x >> 18) | (x << 14))
                   ^ (x >> 3);
        }

        private uint Ro1(uint x)
        {
            return ((x >> 17) | (x << 15))
                   ^ ((x >> 19) | (x << 13))
                   ^ (x >> 10);
        }

        private uint Sig0(uint x)
        {
            return ((x >> 2) | (x << 30))
                   ^ ((x >> 13) | (x << 19))
                   ^ ((x >> 22) | (x << 10));
        }

        private uint Sig1(uint x)
        {
            return ((x >> 6) | (x << 26))
                   ^ ((x >> 11) | (x << 21))
                   ^ ((x >> 25) | (x << 7));
        }

        protected override void HashCore(byte[] rgb, int start, int size)
        {
            int i;
            State = 1;

            if (_ProcessingBufferCount != 0)
            {
                if (size < BLOCK_SIZE_BYTES - _ProcessingBufferCount)
                {
                    BlockCopy(rgb, start, _ProcessingBuffer, _ProcessingBufferCount, size);
                    _ProcessingBufferCount += size;
                    return;
                }

                i = BLOCK_SIZE_BYTES - _ProcessingBufferCount;
                BlockCopy(rgb, start, _ProcessingBuffer, _ProcessingBufferCount, i);
                ProcessBlock(_ProcessingBuffer, 0);
                _ProcessingBufferCount = 0;
                start += i;
                size -= i;
            }

            for (i = 0; i < size - size % BLOCK_SIZE_BYTES; i += BLOCK_SIZE_BYTES) ProcessBlock(rgb, start + i);

            if (size % BLOCK_SIZE_BYTES != 0)
            {
                BlockCopy(rgb, size - size % BLOCK_SIZE_BYTES + start, _ProcessingBuffer, 0, size % BLOCK_SIZE_BYTES);
                _ProcessingBufferCount = size % BLOCK_SIZE_BYTES;
            }
        }

        protected override byte[] HashFinal()
        {
            byte[] hash = new byte[32];
            int i, j;

            ProcessFinalBlock(_ProcessingBuffer, 0, _ProcessingBufferCount);

            for (i = 0; i < 8; i++)
            for (j = 0; j < 4; j++)
                hash[i * 4 + j] = (byte)(_H[i] >> (24 - j * 8));

            State = 0;
            return hash;
        }

        public override void Initialize()
        {
            count = 0;
            _ProcessingBufferCount = 0;

            _H[0] = 0x6A09E667;
            _H[1] = 0xBB67AE85;
            _H[2] = 0x3C6EF372;
            _H[3] = 0xA54FF53A;
            _H[4] = 0x510E527F;
            _H[5] = 0x9B05688C;
            _H[6] = 0x1F83D9AB;
            _H[7] = 0x5BE0CD19;
        }

        private void ProcessBlock(byte[] inputBuffer, int inputOffset)
        {
            uint a, b, c, d, e, f, g, h;
            uint t1, t2;
            int i;

            count += BLOCK_SIZE_BYTES;

            for (i = 0; i < 16; i++)
                buff[i] = ((uint)inputBuffer[inputOffset + 4 * i] << 24)
                          | ((uint)inputBuffer[inputOffset + 4 * i + 1] << 16)
                          | ((uint)inputBuffer[inputOffset + 4 * i + 2] << 8)
                          | inputBuffer[inputOffset + 4 * i + 3];


            for (i = 16; i < 64; i++) buff[i] = Ro1(buff[i - 2]) + buff[i - 7] + Ro0(buff[i - 15]) + buff[i - 16];

            a = _H[0];
            b = _H[1];
            c = _H[2];
            d = _H[3];
            e = _H[4];
            f = _H[5];
            g = _H[6];
            h = _H[7];

            for (i = 0; i < 64; i++)
            {
                t1 = h + Sig1(e) + Ch(e, f, g) + SHAConstants.K1[i] + buff[i];
                t2 = Sig0(a) + Maj(a, b, c);
                h = g;
                g = f;
                f = e;
                e = d + t1;
                d = c;
                c = b;
                b = a;
                a = t1 + t2;
            }

            _H[0] += a;
            _H[1] += b;
            _H[2] += c;
            _H[3] += d;
            _H[4] += e;
            _H[5] += f;
            _H[6] += g;
            _H[7] += h;
        }

        private void ProcessFinalBlock(byte[] inputBuffer, int inputOffset, int inputCount)
        {
            ulong total = count + (ulong)inputCount;
            int paddingSize = 56 - (int)(total % BLOCK_SIZE_BYTES);

            if (paddingSize < 1)
                paddingSize += BLOCK_SIZE_BYTES;

            byte[] fooBuffer = new byte[inputCount + paddingSize + 8];

            for (int i = 0; i < inputCount; i++) fooBuffer[i] = inputBuffer[i + inputOffset];

            fooBuffer[inputCount] = 0x80;
            for (int i = inputCount + 1; i < inputCount + paddingSize; i++) fooBuffer[i] = 0x00;

            // I deal in bytes. The algorithm deals in bits.
            ulong size = total << 3;
            AddLength(size, fooBuffer, inputCount + paddingSize);
            ProcessBlock(fooBuffer, 0);

            if (inputCount + paddingSize + 8 == 128) ProcessBlock(fooBuffer, 64);
        }

        internal void AddLength(ulong length, byte[] buffer, int position)
        {
            buffer[position++] = (byte)(length >> 56);
            buffer[position++] = (byte)(length >> 48);
            buffer[position++] = (byte)(length >> 40);
            buffer[position++] = (byte)(length >> 32);
            buffer[position++] = (byte)(length >> 24);
            buffer[position++] = (byte)(length >> 16);
            buffer[position++] = (byte)(length >> 8);
            buffer[position] = (byte)length;
        }

#if NETCOREAPP
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
#endif
        private void BlockCopy(byte[] src, int srcOffset, byte[] dest, int destOffset, int count)
        {
            if (Unsafe)
                ByteBuffer.BlockCopy_Unsafe(src, srcOffset, dest, destOffset, count);
            else
                ByteBuffer.BlockCopy_Slow(src, srcOffset, dest, destOffset, count);
        }
    }
}//
// System.Security.Cryptography.SHAConstants.cs
//
// Copyright (C) 2004-2005 Novell, Inc (http://www.novell.com)
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

namespace Benchmark.Imported.Cryptography
{
    internal sealed class SHAConstants
    {
        // SHA-256 Constants
        // Represent the first 32 bits of the fractional parts of the
        // cube roots of the first sixty-four prime numbers
        public static readonly uint[] K1 =
        {
            0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5,
            0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
            0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3,
            0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
            0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC,
            0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
            0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7,
            0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
            0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13,
            0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
            0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3,
            0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
            0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5,
            0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
            0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208,
            0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2
        };

        // SHA-384 and SHA-512 Constants
        // Represent the first 64 bits of the fractional parts of the
        // cube roots of the first sixty-four prime numbers
        public static readonly ulong[] K2 =
        {
            0x428a2f98d728ae22L, 0x7137449123ef65cdL, 0xb5c0fbcfec4d3b2fL, 0xe9b5dba58189dbbcL,
            0x3956c25bf348b538L, 0x59f111f1b605d019L, 0x923f82a4af194f9bL, 0xab1c5ed5da6d8118L,
            0xd807aa98a3030242L, 0x12835b0145706fbeL, 0x243185be4ee4b28cL, 0x550c7dc3d5ffb4e2L,
            0x72be5d74f27b896fL, 0x80deb1fe3b1696b1L, 0x9bdc06a725c71235L, 0xc19bf174cf692694L,
            0xe49b69c19ef14ad2L, 0xefbe4786384f25e3L, 0x0fc19dc68b8cd5b5L, 0x240ca1cc77ac9c65L,
            0x2de92c6f592b0275L, 0x4a7484aa6ea6e483L, 0x5cb0a9dcbd41fbd4L, 0x76f988da831153b5L,
            0x983e5152ee66dfabL, 0xa831c66d2db43210L, 0xb00327c898fb213fL, 0xbf597fc7beef0ee4L,
            0xc6e00bf33da88fc2L, 0xd5a79147930aa725L, 0x06ca6351e003826fL, 0x142929670a0e6e70L,
            0x27b70a8546d22ffcL, 0x2e1b21385c26c926L, 0x4d2c6dfc5ac42aedL, 0x53380d139d95b3dfL,
            0x650a73548baf63deL, 0x766a0abb3c77b2a8L, 0x81c2c92e47edaee6L, 0x92722c851482353bL,
            0xa2bfe8a14cf10364L, 0xa81a664bbc423001L, 0xc24b8b70d0f89791L, 0xc76c51a30654be30L,
            0xd192e819d6ef5218L, 0xd69906245565a910L, 0xf40e35855771202aL, 0x106aa07032bbd1b8L,
            0x19a4c116b8d2d0c8L, 0x1e376c085141ab53L, 0x2748774cdf8eeb99L, 0x34b0bcb5e19b48a8L,
            0x391c0cb3c5c95a63L, 0x4ed8aa4ae3418acbL, 0x5b9cca4f7763e373L, 0x682e6ff3d6b2b8a3L,
            0x748f82ee5defb2fcL, 0x78a5636f43172f60L, 0x84c87814a1f0ab72L, 0x8cc702081a6439ecL,
            0x90befffa23631e28L, 0xa4506cebde82bde9L, 0xbef9a3f7b2c67915L, 0xc67178f2e372532bL,
            0xca273eceea26619cL, 0xd186b8c721c0c207L, 0xeada7dd6cde0eb1eL, 0xf57d4f7fee6ed178L,
            0x06f067aa72176fbaL, 0x0a637dc5a2c898a6L, 0x113f9804bef90daeL, 0x1b710b35131c471bL,
            0x28db77f523047d84L, 0x32caab7b40c72493L, 0x3c9ebe0a15c9bebcL, 0x431d67c49c100d4cL,
            0x4cc5d4becb3e42b6L, 0x597f299cfc657e2aL, 0x5fcb6fab3ad6faecL, 0x6c44198c4a475817L
        };

        private SHAConstants()
        {
            // Never instantiated.
        }
    }
}